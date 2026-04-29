export type DonationAlertsTokenResponse = {
  token_type: "Bearer" | string;
  access_token: string;
  refresh_token: string;
  expires_in: number;
};

export type DonationAlertsRefreshTokenResponse = {
  token_type: "Bearer" | string;
  access_token: string;
  refresh_token?: string;
  expires_in: number;
};

export type DonationAlertsUser = {
  id: number;
  code: string;
  name: string;
  avatar: string;
  email: string;
  socket_connection_token: string;
};

export type DonationAlertsApiResponse<T> = {
  data: T;
};

export type DonationAlertsDonation = {
  id: number;
  name: "donation" | string;
  username: string;
  message_type: "text" | "audio" | string;
  message: string;
  amount: number;
  currency: string;
  is_shown: 0 | 1 | number;
  created_at: string;
  shown_at: string | null;
};

export type DonationAlertsDonationListResponse = {
  data: DonationAlertsDonation[];
  links?: {
    first: string | null;
    last: string | null;
    prev: string | null;
    next: string | null;
  };
  meta?: {
    current_page: number;
    from: number | null;
    last_page: number;
    path: string;
    per_page: number;
    to: number | null;
    total: number;
  };
};

export type CentrifugoConnectResponse = {
  id: number;
  result?: {
    client: string;
    version: string;
  };
  error?: unknown;
};

export type DonationAlertsCentrifugeSubscribeResponse = {
  channels: {
    channel: string;
    token: string;
  }[];
};

export type CentrifugoPublicationMessage = {
  result?: {
    type?: number;
    channel?: string;
    data?: {
      data?: DonationAlertsDonation & {
        reason?: string;
      };
      reason?: string;
      [key: string]: unknown;
    };
  };
  method?: number;
  params?: unknown;
  id?: number;
  error?: unknown;
};
