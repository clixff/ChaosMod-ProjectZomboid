import { DONATIONALERTS_API_BASE } from "./constants.ts";
import { getBearer, postBearerJson } from "./http.ts";
import type {
  DonationAlertsApiResponse,
  DonationAlertsCentrifugeSubscribeResponse,
  DonationAlertsDonationListResponse,
  DonationAlertsUser,
} from "./types.ts";

export async function getCurrentDonationAlertsUser(
  accessToken: string,
): Promise<DonationAlertsUser> {
  const response = await getBearer<DonationAlertsApiResponse<DonationAlertsUser>>(
    `${DONATIONALERTS_API_BASE}/user/oauth`,
    accessToken,
  );
  return response.data;
}

export async function getDonationAlertsDonations(
  accessToken: string,
  page = 1,
): Promise<DonationAlertsDonationListResponse> {
  return getBearer<DonationAlertsDonationListResponse>(
    `${DONATIONALERTS_API_BASE}/alerts/donations?page=${page}`,
    accessToken,
  );
}

export async function subscribeDonationAlertsCentrifugeChannel(params: {
  accessToken: string;
  channel: string;
  client: string;
}): Promise<DonationAlertsCentrifugeSubscribeResponse> {
  return postBearerJson<DonationAlertsCentrifugeSubscribeResponse>(
    `${DONATIONALERTS_API_BASE}/centrifuge/subscribe`,
    params.accessToken,
    {
      channels: [params.channel],
      client: params.client,
    },
  );
}
