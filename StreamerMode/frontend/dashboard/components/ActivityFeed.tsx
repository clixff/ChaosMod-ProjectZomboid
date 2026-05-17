import { useEffect, useRef, useState } from "react";
import type { ReactNode } from "react";
import type { ActivityEvent } from "../api.ts";

interface ActivityFeedProps {
  events: ActivityEvent[];
}

function formatTime(ts: number): string {
  const d = new Date(ts);
  const hh = String(d.getHours()).padStart(2, "0");
  const mm = String(d.getMinutes()).padStart(2, "0");
  const ss = String(d.getSeconds()).padStart(2, "0");
  return `${hh}:${mm}:${ss}`;
}

function renderText(event: ActivityEvent): {
  message: ReactNode;
  className: string;
} {
  switch (event.type) {
    case "vote":
      return {
        className: "activity-row activity-row--vote",
        message: (
          <>
            Activate effect by vote:{" "}
            <span className="activity-effect">{event.effect_name}</span>
          </>
        ),
      };
    case "donate": {
      const priceLabel =
        event.price != null
          ? `${event.price}`
          : event.price_group || "donation";
      return {
        className: "activity-row activity-row--donate",
        message: (
          <>
            <span className="activity-nickname">
              {event.nickname || "Anonymous"}
            </span>{" "}
            activated effect for {priceLabel}:{" "}
            <span className="activity-effect">{event.effect_name}</span>
          </>
        ),
      };
    }
    case "donate_failed_price":
      return {
        className: "activity-row activity-row--warn",
        message: (
          <>
            <span className="activity-nickname">
              {event.nickname || "Anonymous"}
            </span>{" "}
            tried to activate{" "}
            <span className="activity-effect">{event.effect_name}</span> for{" "}
            {event.donation_amount}, but effect price is {event.required_price}
          </>
        ),
      };
    case "donate_failed_disabled":
      return {
        className: "activity-row activity-row--warn",
        message: (
          <>
            <span className="activity-nickname">
              {event.nickname || "Anonymous"}
            </span>{" "}
            tried to activate{" "}
            <span className="activity-effect">{event.effect_name}</span> for{" "}
            {event.donation_amount}, but effect donation status is false
          </>
        ),
      };
    case "chat_connected":
      return {
        className: "activity-row activity-row--ok",
        message: <>Connected to Twitch chat</>,
      };
    case "chat_disconnected":
      return {
        className: "activity-row activity-row--warn",
        message: <>Disconnected from Twitch chat</>,
      };
    case "donationalerts_connected":
      return {
        className: "activity-row activity-row--ok",
        message: <>Connected to DonationAlerts Server</>,
      };
    case "donationalerts_disconnected":
      return {
        className: "activity-row activity-row--warn",
        message: <>Disconnected from DonationAlerts Server</>,
      };
    case "youtube_chat_connected":
      return {
        className: "activity-row activity-row--ok",
        message: <>Connected to YouTube chat</>,
      };
    case "youtube_chat_disconnected":
      return {
        className: "activity-row activity-row--warn",
        message: <>Disconnected from YouTube chat</>,
      };
  }
}

export function ActivityFeed({ events }: ActivityFeedProps) {
  const scrollRef = useRef<HTMLDivElement | null>(null);
  const [stickToBottom, setStickToBottom] = useState(true);

  useEffect(() => {
    const el = scrollRef.current;
    if (!el || !stickToBottom) return;
    el.scrollTop = el.scrollHeight;
  }, [events, stickToBottom]);

  const onScroll = () => {
    const el = scrollRef.current;
    if (!el) return;
    const distanceFromBottom = el.scrollHeight - el.scrollTop - el.clientHeight;
    setStickToBottom(distanceFromBottom < 24);
  };

  return (
    <aside className="activity-panel">
      <div className="activity-card">
        <div className="activity-header">
          <h3 className="activity-title">Latest Events</h3>
          <span className="activity-count">{events.length}</span>
        </div>
        <div className="activity-list" ref={scrollRef} onScroll={onScroll}>
          {events.length === 0 && (
            <div className="activity-empty">No activity yet.</div>
          )}
          {events.map((event) => {
            const { message, className } = renderText(event);
            return (
              <div key={event.id} className={className}>
                <div className="activity-time">{formatTime(event.ts)}</div>
                <div className="activity-message">{message}</div>
              </div>
            );
          })}
        </div>
      </div>
    </aside>
  );
}
