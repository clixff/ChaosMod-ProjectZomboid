import { DONATIONALERTS_CENTRIFUGO_WS_URL } from "./constants.ts";
import { subscribeDonationAlertsCentrifugeChannel } from "./api.ts";
import type {
  CentrifugoConnectResponse,
  CentrifugoPublicationMessage,
  DonationAlertsDonation,
  DonationAlertsUser,
} from "./types.ts";

export type ListenDonationAlertsOptions = {
  accessToken: string;
  user: DonationAlertsUser;
  onDonation: (donation: DonationAlertsDonation, raw: unknown) => void;
  onLog?: (message: string) => void;
  onError?: (error: unknown) => void;
};

export async function listenDonationAlertsDonations(
  options: ListenDonationAlertsOptions,
): Promise<WebSocket> {
  const log = options.onLog ?? (() => {});
  const onError = options.onError ?? console.error;

  return new Promise((resolve, reject) => {
    const ws = new WebSocket(DONATIONALERTS_CENTRIFUGO_WS_URL);
    let messageId = 1;
    let isSubscribed = false;
    let settled = false;

    ws.addEventListener("open", () => {
      log("Centrifugo WebSocket opened");
      ws.send(
        JSON.stringify({
          params: { token: options.user.socket_connection_token },
          id: messageId++,
        }),
      );
    });

    ws.addEventListener("message", async (event) => {
      try {
        const rawText =
          typeof event.data === "string"
            ? event.data
            : await new Response(event.data as BodyInit).text();

        const lines = rawText
          .split("\n")
          .map((line) => line.trim())
          .filter(Boolean);

        for (const line of lines) {
          await handleMessage(JSON.parse(line) as unknown);
        }
      } catch (error) {
        onError(error);
      }
    });

    ws.addEventListener("error", (event) => {
      onError(event);
      if (!settled) {
        settled = true;
        reject(new Error("WebSocket connection failed"));
      }
    });

    ws.addEventListener("close", (event) => {
      log(`Centrifugo WebSocket closed: ${event.code} ${event.reason}`);
    });

    async function handleMessage(message: unknown): Promise<void> {
      const connectMessage = message as CentrifugoConnectResponse;

      if (connectMessage.id === 1 && connectMessage.result?.client && !isSubscribed) {
        const client = connectMessage.result.client;
        const channel = `$alerts:donation_${options.user.id}`;

        log(`Centrifugo client id: ${client}`);
        log(`Subscribing to channel: ${channel}`);

        const subscribeResponse = await subscribeDonationAlertsCentrifugeChannel({
          accessToken: options.accessToken,
          client,
          channel,
        });

        const subscription = subscribeResponse.channels.find(
          (item) => item.channel === channel,
        );

        if (!subscription) {
          const err = new Error(`DonationAlerts did not return token for channel ${channel}`);
          onError(err);
          if (!settled) {
            settled = true;
            reject(err);
          }
          return;
        }

        ws.send(
          JSON.stringify({
            params: { channel: subscription.channel, token: subscription.token },
            method: 1,
            id: messageId++,
          }),
        );

        isSubscribed = true;
        log("Subscribed to DonationAlerts donation channel");

        if (!settled) {
          settled = true;
          resolve(ws);
        }
        return;
      }

      const publication = message as CentrifugoPublicationMessage;
      const donation = extractDonation(publication);
      if (donation) {
        options.onDonation(donation, message);
      }
    }
  });
}

function extractDonation(message: CentrifugoPublicationMessage): DonationAlertsDonation | null {
  const data = message.result?.data;
  if (!data) return null;

  const candidate =
    data.data && typeof data.data === "object" ? data.data : data;

  if (
    typeof candidate === "object" &&
    candidate !== null &&
    "id" in candidate &&
    "username" in candidate &&
    "amount" in candidate
  ) {
    return candidate as DonationAlertsDonation;
  }

  return null;
}
