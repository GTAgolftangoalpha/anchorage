import * as functions from "firebase-functions/v2";
import * as admin from "firebase-admin";
import * as sgMail from "@sendgrid/mail";

admin.initializeApp();
const db = admin.firestore();

// SendGrid API key stored as Firebase secret:
//   firebase functions:secrets:set SENDGRID_API_KEY
// Then deploy — Functions runtime injects it at startup.
const SENDGRID_API_KEY = process.env.SENDGRID_API_KEY ?? "";
const FROM_EMAIL = "gtagolftangoalpha@gmail.com";
const FROM_NAME = "ANCHORAGE";
const APP_URL = "https://anchorage.app";

// Initialise SendGrid lazily so cold starts don't fail if the secret
// hasn't been set yet (local emulator, CI, etc.)
function getSgMail(): typeof sgMail {
  if (!SENDGRID_API_KEY) {
    throw new Error("SENDGRID_API_KEY secret is not set");
  }
  sgMail.setApiKey(SENDGRID_API_KEY);
  return sgMail;
}

// ── Types ──────────────────────────────────────────────────────────────────

interface PartnerDoc {
  partnerEmail: string;
  partnerName: string;
  userName: string;     // Display name of the ANCHORAGE user
  userId: string;
  status: "invited" | "accepted" | "declined";
  invitedAt: admin.firestore.Timestamp;
  acceptedAt?: admin.firestore.Timestamp;
  inviteToken: string;  // UUID used in accept/decline links
  unsubscribeToken: string;
}

interface UserStats {
  streakDays: number;
  interceptCount: number;
  reflectionCount: number;
  weeklyIntercepts: number;
  weeklyReflections: number;
  lastUpdated: admin.firestore.Timestamp;
}

// ── Part 2: Partner invitation email ──────────────────────────────────────

/**
 * Triggered when a new partner document is created under
 * users/{userId}/partners/{partnerId}.
 * Sends a branded invitation email to the partner.
 */
export const onPartnerInvited = functions.firestore.onDocumentCreated(
  "users/{userId}/partners/{partnerId}",
  async (event) => {
    const data = event.data?.data() as PartnerDoc | undefined;
    if (!data) return;

    const {partnerEmail, partnerName, userName, inviteToken, userId} = data;

    const acceptUrl =
      `${APP_URL}/partner-accept?token=${inviteToken}&action=accept&uid=${userId}`;
    const declineUrl =
      `${APP_URL}/partner-accept?token=${inviteToken}&action=decline&uid=${userId}`;

    const subject = `${userName} has added you as their accountability partner`;

    const html = partnerInviteHtml({
      partnerName,
      userName,
      acceptUrl,
      declineUrl,
    });

    try {
      await getSgMail().send({
        to: {email: partnerEmail, name: partnerName},
        from: {email: FROM_EMAIL, name: FROM_NAME},
        subject,
        html,
      });
      functions.logger.info(
        `[onPartnerInvited] Invitation sent to ${partnerEmail} for user ${userId}`
      );
    } catch (err: unknown) {
      const sgErr = err as { response?: { body?: unknown } };
      functions.logger.error(
        "[onPartnerInvited] SendGrid error:",
        sgErr.response?.body ?? err
      );
    }
  }
);

// ── Part 3: Weekly accountability report ──────────────────────────────────

/**
 * Runs every Monday at 9:00 AM UTC.
 * Sends a weekly progress report to all accepted accountability partners.
 */
export const sendWeeklyReport = functions.scheduler.onSchedule(
  {
    schedule: "every monday 09:00",
    timeZone: "UTC",
  },
  async () => {
    functions.logger.info("[sendWeeklyReport] Starting weekly report run");

    // Fetch all accepted partnerships
    const snapshot = await db
      .collectionGroup("partners")
      .where("status", "==", "accepted")
      .get();

    functions.logger.info(
      `[sendWeeklyReport] Found ${snapshot.docs.length} accepted partners`
    );

    const sends: Promise<void>[] = [];

    for (const partnerDoc of snapshot.docs) {
      const partner = partnerDoc.data() as PartnerDoc;
      const userId = partner.userId;

      sends.push(
        sendReportForPartner(userId, partner).catch((err) => {
          functions.logger.error(
            `[sendWeeklyReport] Failed for partner ${partner.partnerEmail}:`,
            err
          );
        })
      );
    }

    await Promise.all(sends);
    functions.logger.info("[sendWeeklyReport] Weekly report run complete");
  }
);

async function sendReportForPartner(
  userId: string,
  partner: PartnerDoc
): Promise<void> {
  // Load user's stats document
  const statsSnap = await db
    .collection("users")
    .doc(userId)
    .collection("stats")
    .doc("current")
    .get();

  const stats = statsSnap.exists
    ? (statsSnap.data() as UserStats)
    : {
      streakDays: 0,
      weeklyIntercepts: 0,
      weeklyReflections: 0,
    };

  const subject = `${partner.userName}'s weekly ANCHORAGE report`;

  const unsubscribeUrl =
    `${APP_URL}/partner-unsubscribe?token=${partner.unsubscribeToken}&uid=${userId}`;

  const html = weeklyReportHtml({
    partnerName: partner.partnerName,
    userName: partner.userName,
    streakDays: stats.streakDays ?? 0,
    weeklyIntercepts: stats.weeklyIntercepts ?? 0,
    weeklyReflections: stats.weeklyReflections ?? 0,
    unsubscribeUrl,
  });

  await getSgMail().send({
    to: {email: partner.partnerEmail, name: partner.partnerName},
    from: {email: FROM_EMAIL, name: FROM_NAME},
    subject,
    html,
  });

  functions.logger.info(
    `[sendReportForPartner] Report sent to ${partner.partnerEmail} for user ${userId}`
  );
}

// ── Part 2 continued: Accept / Decline HTTP endpoint ──────────────────────

/**
 * HTTPS endpoint that handles accept/decline link clicks from the email.
 * Updates the partner document status in Firestore.
 *
 * GET /partnerRespond?token=<inviteToken>&action=accept|decline&uid=<userId>
 */
export const partnerRespond = functions.https.onRequest(
  {},
  async (req, res) => {
    const {token, action, uid} = req.query as Record<string, string>;

    if (!token || !uid || (action !== "accept" && action !== "decline")) {
      res.status(400).send("Invalid link.");
      return;
    }

    // Find the partner document by inviteToken
    const partnersSnap = await db
      .collection("users")
      .doc(uid)
      .collection("partners")
      .where("inviteToken", "==", token)
      .limit(1)
      .get();

    if (partnersSnap.empty) {
      res.status(404).send("Invitation not found or already responded.");
      return;
    }

    const partnerRef = partnersSnap.docs[0].ref;
    const partner = partnersSnap.docs[0].data() as PartnerDoc;

    if (partner.status !== "invited") {
      res
        .status(200)
        .send(alreadyRespondedHtml(partner.status, partner.userName));
      return;
    }

    const newStatus = action === "accept" ? "accepted" : "declined";
    await partnerRef.update({
      status: newStatus,
      acceptedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    functions.logger.info(
      `[partnerRespond] ${partner.partnerEmail} ${newStatus} invite for user ${uid}`
    );

    res.status(200).send(respondedHtml(newStatus, partner.userName));
  }
);

// ── Email templates ────────────────────────────────────────────────────────

function partnerInviteHtml(opts: {
  partnerName: string;
  userName: string;
  acceptUrl: string;
  declineUrl: string;
}): string {
  const {partnerName, userName, acceptUrl, declineUrl} = opts;
  return `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <title>ANCHORAGE Accountability Invitation</title>
</head>
<body style="margin:0;padding:0;background:#F5F7FA;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#F5F7FA;padding:40px 20px;">
    <tr><td align="center">
      <table width="560" cellpadding="0" cellspacing="0"
             style="background:#ffffff;border-radius:16px;overflow:hidden;max-width:560px;width:100%;">

        <!-- Header -->
        <tr>
          <td style="background:#0A1628;padding:32px 40px;text-align:center;">
            <p style="margin:0;font-size:28px;color:#ffffff;letter-spacing:4px;font-weight:700;">
              ⚓ ANCHORAGE
            </p>
          </td>
        </tr>

        <!-- Body -->
        <tr>
          <td style="padding:40px;">
            <p style="margin:0 0 16px;font-size:22px;font-weight:700;color:#0A1628;">
              Hi ${escapeHtml(partnerName)},
            </p>
            <p style="margin:0 0 24px;font-size:16px;color:#4A6080;line-height:1.6;">
              <strong>${escapeHtml(userName)}</strong> is on a journey to break free from
              pornography, and they've chosen you as their accountability partner on
              <strong>ANCHORAGE</strong>.
            </p>
            <p style="margin:0 0 24px;font-size:16px;color:#4A6080;line-height:1.6;">
              As their partner, you'll receive a brief weekly email with their progress —
              streak days, reflection count, and how they're going. No judgment, just support.
            </p>

            <!-- Accept button -->
            <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:16px;">
              <tr>
                <td align="center">
                  <a href="${acceptUrl}"
                     style="display:inline-block;background:#0A1628;color:#ffffff;
                            text-decoration:none;padding:16px 48px;border-radius:12px;
                            font-size:16px;font-weight:700;letter-spacing:1px;">
                    ACCEPT &amp; SUPPORT ${escapeHtml(userName.toUpperCase())}
                  </a>
                </td>
              </tr>
            </table>

            <!-- Decline link -->
            <p style="margin:0;text-align:center;">
              <a href="${declineUrl}"
                 style="font-size:13px;color:#8FA3B1;text-decoration:underline;">
                No thanks, decline this invitation
              </a>
            </p>
          </td>
        </tr>

        <!-- Footer -->
        <tr>
          <td style="background:#F5F7FA;padding:24px 40px;text-align:center;
                     border-top:1px solid #D1D9E0;">
            <p style="margin:0;font-size:12px;color:#8FA3B1;line-height:1.6;">
              You received this because ${escapeHtml(userName)} added your email as their
              accountability partner on ANCHORAGE. If this was a mistake, simply decline above.
            </p>
          </td>
        </tr>

      </table>
    </td></tr>
  </table>
</body>
</html>`;
}

function weeklyReportHtml(opts: {
  partnerName: string;
  userName: string;
  streakDays: number;
  weeklyIntercepts: number;
  weeklyReflections: number;
  unsubscribeUrl: string;
}): string {
  const {
    partnerName, userName, streakDays,
    weeklyIntercepts, weeklyReflections, unsubscribeUrl,
  } = opts;

  const streakEmoji = streakDays >= 30 ? "🔥" :
    streakDays >= 7 ? "⭐" : "⚓";

  const encouragement = streakDays === 0
    ? "Every journey starts with a single step. They're still in the fight."
    : streakDays < 7
      ? `${streakDays} day${streakDays !== 1 ? "s" : ""} is a real start — steady progress.`
      : `${streakDays} days is something to be proud of. Keep cheering them on.`;

  return `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <title>Weekly ANCHORAGE Report</title>
</head>
<body style="margin:0;padding:0;background:#F5F7FA;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#F5F7FA;padding:40px 20px;">
    <tr><td align="center">
      <table width="560" cellpadding="0" cellspacing="0"
             style="background:#ffffff;border-radius:16px;overflow:hidden;max-width:560px;width:100%;">

        <!-- Header -->
        <tr>
          <td style="background:#0A1628;padding:32px 40px;text-align:center;">
            <p style="margin:0;font-size:28px;color:#ffffff;letter-spacing:4px;font-weight:700;">
              ⚓ ANCHORAGE
            </p>
            <p style="margin:8px 0 0;font-size:14px;color:#7EC8C8;letter-spacing:2px;">
              WEEKLY PROGRESS REPORT
            </p>
          </td>
        </tr>

        <!-- Greeting -->
        <tr>
          <td style="padding:32px 40px 0;">
            <p style="margin:0;font-size:20px;font-weight:700;color:#0A1628;">
              Hi ${escapeHtml(partnerName)},
            </p>
            <p style="margin:12px 0 0;font-size:15px;color:#4A6080;line-height:1.6;">
              Here's how <strong>${escapeHtml(userName)}</strong> did this week on ANCHORAGE.
            </p>
          </td>
        </tr>

        <!-- Stats grid -->
        <tr>
          <td style="padding:24px 40px;">
            <table width="100%" cellpadding="0" cellspacing="0">
              <tr>
                <!-- Streak -->
                <td width="33%" style="text-align:center;padding:16px 8px;
                    background:#F5F7FA;border-radius:12px;margin:4px;">
                  <p style="margin:0;font-size:32px;">${streakEmoji}</p>
                  <p style="margin:8px 0 0;font-size:28px;font-weight:700;color:#0A1628;">
                    ${streakDays}
                  </p>
                  <p style="margin:4px 0 0;font-size:12px;color:#8FA3B1;
                     letter-spacing:1px;text-transform:uppercase;">
                    Day Streak
                  </p>
                </td>
                <td width="4px"></td>
                <!-- Intercepts -->
                <td width="33%" style="text-align:center;padding:16px 8px;
                    background:#F5F7FA;border-radius:12px;">
                  <p style="margin:0;font-size:32px;">🛡️</p>
                  <p style="margin:8px 0 0;font-size:28px;font-weight:700;color:#0A1628;">
                    ${weeklyIntercepts}
                  </p>
                  <p style="margin:4px 0 0;font-size:12px;color:#8FA3B1;
                     letter-spacing:1px;text-transform:uppercase;">
                    Times Anchored
                  </p>
                </td>
                <td width="4px"></td>
                <!-- Reflections -->
                <td width="33%" style="text-align:center;padding:16px 8px;
                    background:#F5F7FA;border-radius:12px;">
                  <p style="margin:0;font-size:32px;">📝</p>
                  <p style="margin:8px 0 0;font-size:28px;font-weight:700;color:#0A1628;">
                    ${weeklyReflections}
                  </p>
                  <p style="margin:4px 0 0;font-size:12px;color:#8FA3B1;
                     letter-spacing:1px;text-transform:uppercase;">
                    Reflections
                  </p>
                </td>
              </tr>
            </table>
          </td>
        </tr>

        <!-- Encouragement -->
        <tr>
          <td style="padding:0 40px 32px;">
            <div style="background:#0A1628;border-radius:12px;padding:20px 24px;">
              <p style="margin:0;font-size:15px;color:#7EC8C8;line-height:1.6;">
                ${escapeHtml(encouragement)}
              </p>
            </div>
          </td>
        </tr>

        <!-- CTA -->
        <tr>
          <td style="padding:0 40px 32px;text-align:center;">
            <p style="margin:0 0 16px;font-size:14px;color:#4A6080;">
              A message of encouragement goes a long way. Let them know you're with them.
            </p>
          </td>
        </tr>

        <!-- Footer -->
        <tr>
          <td style="background:#F5F7FA;padding:24px 40px;text-align:center;
                     border-top:1px solid #D1D9E0;">
            <p style="margin:0;font-size:12px;color:#8FA3B1;line-height:1.6;">
              You're receiving this as ${escapeHtml(userName)}'s accountability partner
              on ANCHORAGE. &nbsp;·&nbsp;
              <a href="${unsubscribeUrl}"
                 style="color:#8FA3B1;text-decoration:underline;">Unsubscribe</a>
            </p>
          </td>
        </tr>

      </table>
    </td></tr>
  </table>
</body>
</html>`;
}

function respondedHtml(status: "accepted" | "declined", userName: string): string {
  const accepted = status === "accepted";
  return `<!DOCTYPE html><html><body style="font-family:Arial;text-align:center;padding:60px 20px;background:#F5F7FA;">
    <h1 style="color:#0A1628;">⚓ ANCHORAGE</h1>
    <h2 style="color:${accepted ? "#2ECC71" : "#8FA3B1"};">
      ${accepted ? "You're now an accountability partner!" : "Invitation declined."}
    </h2>
    <p style="color:#4A6080;max-width:400px;margin:16px auto;">
      ${accepted
    ? `Thank you for supporting ${escapeHtml(userName)}. You'll receive a brief weekly progress email. It means a lot.`
    : `No worries — ${escapeHtml(userName)} will be notified.`}
    </p>
  </body></html>`;
}

function alreadyRespondedHtml(
  status: string,
  userName: string
): string {
  return `<!DOCTYPE html><html><body style="font-family:Arial;text-align:center;padding:60px 20px;background:#F5F7FA;">
    <h1 style="color:#0A1628;">⚓ ANCHORAGE</h1>
    <p style="color:#4A6080;max-width:400px;margin:16px auto;">
      You've already ${status} ${escapeHtml(userName)}'s invitation.
    </p>
  </body></html>`;
}

// ── Part 4: Missing heartbeat check ─────────────────────────────────────────

/**
 * Runs every 6 hours. For each user with an accepted accountability partner,
 * checks if the last heartbeat is older than 12 hours. If so, sends a warm
 * non-shaming email to the partner. Only sends once per 24 hours.
 */
export const checkMissingHeartbeats = functions.scheduler.onSchedule(
  {
    schedule: "every 6 hours",
    timeZone: "UTC",
  },
  async () => {
    functions.logger.info("[checkMissingHeartbeats] Starting check");

    // Find all accepted partnerships
    const partnersSnap = await db
      .collectionGroup("partners")
      .where("status", "==", "accepted")
      .get();

    functions.logger.info(
      `[checkMissingHeartbeats] Found ${partnersSnap.docs.length} accepted partners`
    );

    const now = Date.now();
    const TWELVE_HOURS = 12 * 60 * 60 * 1000;
    const TWENTY_FOUR_HOURS = 24 * 60 * 60 * 1000;
    const sends: Promise<void>[] = [];

    for (const partnerDoc of partnersSnap.docs) {
      const partner = partnerDoc.data() as PartnerDoc;
      const userId = partner.userId;

      sends.push(
        checkHeartbeatForUser(userId, partner, now, TWELVE_HOURS, TWENTY_FOUR_HOURS)
          .catch((err) => {
            functions.logger.error(
              `[checkMissingHeartbeats] Failed for user ${userId}:`, err
            );
          })
      );
    }

    await Promise.all(sends);
    functions.logger.info("[checkMissingHeartbeats] Check complete");
  }
);

async function checkHeartbeatForUser(
  userId: string,
  partner: PartnerDoc,
  now: number,
  twelveHours: number,
  twentyFourHours: number
): Promise<void> {
  // Get latest heartbeat
  const heartbeatSnap = await db
    .collection("users")
    .doc(userId)
    .collection("heartbeats")
    .doc("latest")
    .get();

  if (!heartbeatSnap.exists) {
    functions.logger.info(
      `[checkHeartbeatForUser] No heartbeat for user ${userId} — skipping (may be new user)`
    );
    return;
  }

  const heartbeat = heartbeatSnap.data();
  const timestamp = heartbeat?.timestamp as admin.firestore.Timestamp | undefined;
  if (!timestamp) return;

  const heartbeatAge = now - timestamp.toMillis();
  if (heartbeatAge < twelveHours) return; // heartbeat is recent — all good

  // Check if we already sent an alert in the last 24 hours
  const alertsSnap = await db
    .collection("users")
    .doc(userId)
    .collection("heartbeat_alerts")
    .orderBy("sentAt", "desc")
    .limit(1)
    .get();

  if (!alertsSnap.empty) {
    const lastAlert = alertsSnap.docs[0].data();
    const lastSentAt = lastAlert.sentAt as admin.firestore.Timestamp;
    if (now - lastSentAt.toMillis() < twentyFourHours) {
      functions.logger.info(
        `[checkHeartbeatForUser] Already alerted for user ${userId} within 24h — skipping`
      );
      return;
    }
  }

  // Send alert email
  const userName = partner.userName || "Your partner";
  const subject = `Check in with ${userName}`;
  const html = missingHeartbeatHtml(partner.partnerName, userName);

  try {
    await getSgMail().send({
      to: {email: partner.partnerEmail, name: partner.partnerName},
      from: {email: FROM_EMAIL, name: FROM_NAME},
      subject,
      html,
    });

    // Record that we sent this alert
    await db
      .collection("users")
      .doc(userId)
      .collection("heartbeat_alerts")
      .add({sentAt: admin.firestore.FieldValue.serverTimestamp()});

    functions.logger.info(
      `[checkHeartbeatForUser] Missing heartbeat alert sent to ${partner.partnerEmail} for user ${userId}`
    );
  } catch (err: unknown) {
    const sgErr = err as { response?: { body?: unknown } };
    functions.logger.error(
      "[checkHeartbeatForUser] SendGrid error:", sgErr.response?.body ?? err
    );
  }
}

// ── Part 5: Protection alert (VPN/guard tamper events) ─────────────────────

/**
 * Triggered when a tamper event document is created.
 * Sends a warm non-shaming alert to all accepted accountability partners.
 */
export const onTamperEvent = functions.firestore.onDocumentCreated(
  "users/{userId}/tamper_events/{eventId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const userId = event.params.userId;
    const eventType = data.type as string;

    functions.logger.info(
      `[onTamperEvent] Event '${eventType}' for user ${userId}`
    );

    // Get all accepted partners for this user
    const partnersSnap = await db
      .collection("users")
      .doc(userId)
      .collection("partners")
      .where("status", "==", "accepted")
      .get();

    if (partnersSnap.empty) return;

    const sends: Promise<void>[] = [];

    for (const partnerDoc of partnersSnap.docs) {
      const partner = partnerDoc.data() as PartnerDoc;
      const userName = partner.userName || "Your partner";

      let subject: string;
      let html: string;

      if (eventType === "vpn_revoked") {
        subject = `${userName}'s content protection was interrupted`;
        html = protectionAlertHtml(
          partner.partnerName,
          userName,
          "content protection (VPN) was interrupted",
          "This could mean the VPN was disabled by another app or a system update. " +
          "It doesn't necessarily mean anything concerning happened."
        );
      } else {
        subject = `${userName}'s ANCHORAGE protection status changed`;
        html = protectionAlertHtml(
          partner.partnerName,
          userName,
          "protection status changed",
          "A protection feature was modified or disabled."
        );
      }

      sends.push(
        getSgMail().send({
          to: {email: partner.partnerEmail, name: partner.partnerName},
          from: {email: FROM_EMAIL, name: FROM_NAME},
          subject,
          html,
        }).then(() => {
          functions.logger.info(
            `[onTamperEvent] Alert sent to ${partner.partnerEmail}`
          );
        }).catch((err: unknown) => {
          const sgErr = err as { response?: { body?: unknown } };
          functions.logger.error(
            "[onTamperEvent] SendGrid error:", sgErr.response?.body ?? err
          );
        })
      );
    }

    await Promise.all(sends);
  }
);

// ── Email templates (continued) ───────────────────────────────────────────

function missingHeartbeatHtml(partnerName: string, userName: string): string {
  return `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <title>ANCHORAGE Check-In</title>
</head>
<body style="margin:0;padding:0;background:#F5F7FA;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#F5F7FA;padding:40px 20px;">
    <tr><td align="center">
      <table width="560" cellpadding="0" cellspacing="0"
             style="background:#ffffff;border-radius:16px;overflow:hidden;max-width:560px;width:100%;">
        <tr>
          <td style="background:#0A1628;padding:32px 40px;text-align:center;">
            <p style="margin:0;font-size:28px;color:#ffffff;letter-spacing:4px;font-weight:700;">
              &#9875; ANCHORAGE
            </p>
          </td>
        </tr>
        <tr>
          <td style="padding:40px;">
            <p style="margin:0 0 16px;font-size:20px;font-weight:700;color:#0A1628;">
              Hi ${escapeHtml(partnerName)},
            </p>
            <p style="margin:0 0 24px;font-size:16px;color:#4A6080;line-height:1.6;">
              <strong>${escapeHtml(userName)}</strong>'s ANCHORAGE app appears to be
              inactive or may have been uninstalled. This could simply be a phone
              restart, battery optimization, or a technical issue.
            </p>
            <div style="background:#FFF8F0;border-left:4px solid #D4AF37;padding:16px 20px;
                        border-radius:0 8px 8px 0;margin:0 0 24px;">
              <p style="margin:0;font-size:15px;color:#4A6080;line-height:1.6;">
                You may want to <strong>check in with them</strong> &mdash;
                not with judgment, but with care. Everyone's journey has ups and downs.
              </p>
            </div>
            <p style="margin:0;font-size:14px;color:#8FA3B1;line-height:1.6;">
              This is an automated check-in. No browsing data or personal details
              are ever shared. ANCHORAGE only monitors whether the app is running.
            </p>
          </td>
        </tr>
        <tr>
          <td style="background:#F5F7FA;padding:24px 40px;text-align:center;
                     border-top:1px solid #D1D9E0;">
            <p style="margin:0;font-size:12px;color:#8FA3B1;">
              Sent by ANCHORAGE accountability system
            </p>
          </td>
        </tr>
      </table>
    </td></tr>
  </table>
</body>
</html>`;
}

function protectionAlertHtml(
  partnerName: string,
  userName: string,
  eventDescription: string,
  explanation: string
): string {
  return `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <title>ANCHORAGE Protection Alert</title>
</head>
<body style="margin:0;padding:0;background:#F5F7FA;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#F5F7FA;padding:40px 20px;">
    <tr><td align="center">
      <table width="560" cellpadding="0" cellspacing="0"
             style="background:#ffffff;border-radius:16px;overflow:hidden;max-width:560px;width:100%;">
        <tr>
          <td style="background:#0A1628;padding:32px 40px;text-align:center;">
            <p style="margin:0;font-size:28px;color:#ffffff;letter-spacing:4px;font-weight:700;">
              &#9875; ANCHORAGE
            </p>
          </td>
        </tr>
        <tr>
          <td style="padding:40px;">
            <p style="margin:0 0 16px;font-size:20px;font-weight:700;color:#0A1628;">
              Hi ${escapeHtml(partnerName)},
            </p>
            <p style="margin:0 0 24px;font-size:16px;color:#4A6080;line-height:1.6;">
              <strong>${escapeHtml(userName)}</strong>'s ${escapeHtml(eventDescription)}.
            </p>
            <div style="background:#FFF8F0;border-left:4px solid #D4AF37;padding:16px 20px;
                        border-radius:0 8px 8px 0;margin:0 0 24px;">
              <p style="margin:0;font-size:15px;color:#4A6080;line-height:1.6;">
                ${escapeHtml(explanation)}
                A gentle check-in might be appreciated.
              </p>
            </div>
            <p style="margin:0;font-size:14px;color:#8FA3B1;line-height:1.6;">
              No browsing data or personal details are ever shared in these alerts.
            </p>
          </td>
        </tr>
        <tr>
          <td style="background:#F5F7FA;padding:24px 40px;text-align:center;
                     border-top:1px solid #D1D9E0;">
            <p style="margin:0;font-size:12px;color:#8FA3B1;">
              Sent by ANCHORAGE accountability system
            </p>
          </td>
        </tr>
      </table>
    </td></tr>
  </table>
</body>
</html>`;
}

function escapeHtml(str: string): string {
  return str
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}
