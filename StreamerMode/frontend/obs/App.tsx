import { useState, useEffect, useRef, type CSSProperties } from "react";

interface VoteOption {
  effect_id: string;
  index: number;
  effect_name: string;
  votes: number | undefined;
  hidden?: boolean;
  duration?: number;
}

interface TwitchSubsStatus {
  enabled: boolean;
  show_in_obs: boolean;
  current: number;
  threshold: number;
}

interface ModStatus {
  voting_enabled: boolean;
  donateEnabled?: boolean;
  total_votes: number;
  total_votes_label: string;
  vote_background_color: string;
  last_winner: string | null;
  vote_options: VoteOption[];
  twitch_subs?: TwitchSubsStatus;
}

type DisplayMode = "hidden" | "entering" | "voting" | "results" | "hiding";

interface DisplayState {
  mode: DisplayMode;
  options: VoteOption[];
  totalVotes: number;
  totalVotesLabel: string;
  bgColor: string;
  lastWinner: string | null;
  subs: TwitchSubsStatus | null;
  donateEnabled: boolean;
  votingEnabled: boolean;
}

const BAR_WIDTH = 400;
const RESULTS_DURATION_MS = 5000;
const MIN_WINNER_WIDTH_RATIO = 0.5;

function getBarWidth(votes: number | undefined, options: VoteOption[]): number {
  if (votes === undefined) return 0;

  const totalVotes = options.reduce(
    (sum, opt) => sum + (opt.votes ?? 0),
    0,
  );
  if (totalVotes === 0) return 0;

  const winnerVotes = Math.max(
    0,
    ...options.map((opt) => opt.votes ?? 0),
  );
  if (winnerVotes === 0) return 0;

  const naturalWinnerWidth = (winnerVotes / totalVotes) * BAR_WIDTH;
  const winnerWidth = Math.max(
    naturalWinnerWidth,
    BAR_WIDTH * MIN_WINNER_WIDTH_RATIO,
  );

  return Math.round((votes / winnerVotes) * winnerWidth);
}

function formatTotalVotes(value: number): string {
  return value.toString().replace(/\B(?=(\d{3})+(?!\d))/g, " ");
}

function formatOptionVotes(value: number): string {
  if (value < 1000) return String(value);

  if (value < 1_000_000) {
    const compact = value / 1000;
    const decimals = value % 1000 === 0 ? 0 : 1;
    return `${compact.toFixed(decimals).replace(/\.0$/, "")}k`;
  }

  const compact = value / 1_000_000;
  const decimals = value % 1_000_000 === 0 ? 0 : 1;
  return `${compact.toFixed(decimals).replace(/\.0$/, "")}m`;
}

// Renders a vote option name. When the text fits it stays static at 16px.
// When it's too wide it shrinks to 14px and scrolls back and forth (ping-pong
// marquee) to reveal the full name. Every scrolling option uses the same fixed
// cycle duration (defined in CSS) so all options move in sync regardless of
// length — the trade-off is that longer names travel a bit faster.
function OptionName({ text }: { text: string }) {
  const containerRef = useRef<HTMLSpanElement>(null);
  const textRef = useRef<HTMLSpanElement>(null);
  const [scrolling, setScrolling] = useState(false);
  const [shift, setShift] = useState(0);

  useEffect(() => {
    const container = containerRef.current;
    const textEl = textRef.current;
    if (!container || !textEl) return;

    // Measure imperatively so the decision is independent of the current
    // scroll state: force 16px to test the fit, then force 14px to read the
    // real travel distance (the narrower text overflows by less). The inline
    // font size is restored afterwards so the className governs the rendered
    // size again.
    const measure = () => {
      const cw = container.clientWidth;
      const prevFont = textEl.style.fontSize;

      textEl.style.fontSize = "16px";
      const fitsAt16 = textEl.scrollWidth - cw <= 1;
      if (fitsAt16) {
        textEl.style.fontSize = prevFont;
        setScrolling(false);
        setShift(0);
        return;
      }

      textEl.style.fontSize = "14px";
      const distance = textEl.scrollWidth - cw;
      textEl.style.fontSize = prevFont;
      setScrolling(true);
      setShift(distance > 1 ? distance : 0);
    };

    // ResizeObserver delivers an initial callback when observe() is called,
    // which seeds the first measurement (so we never call setState
    // synchronously in the effect body). It also re-measures when the votes
    // count grows and shrinks the name's available width.
    const ro = new ResizeObserver(measure);
    ro.observe(container);

    // Montserrat loads asynchronously; re-measure once it's ready so the
    // overflow check uses real glyph widths instead of the fallback font's.
    let cancelled = false;
    if (document.fonts?.ready) {
      void document.fonts.ready.then(() => {
        if (!cancelled) measure();
      });
    }

    return () => {
      cancelled = true;
      ro.disconnect();
    };
  }, [text]);

  // Cast: CSSProperties doesn't type custom "--" properties in an object
  // literal, but they're valid inline-style values consumed by the keyframes.
  const scrollStyle = { "--marquee-shift": `-${shift}px` } as CSSProperties;

  return (
    <span className="option-name" ref={containerRef}>
      <span
        ref={textRef}
        className={
          scrolling
            ? "option-name-text option-name-text--scroll"
            : "option-name-text"
        }
        style={scrolling ? scrollStyle : undefined}
      >
        {text}
      </span>
    </span>
  );
}

export function App() {
  const [displayState, setDisplayState] = useState<DisplayState>({
    mode: "hidden",
    options: [],
    totalVotes: 0,
    totalVotesLabel: "Total votes: %d",
    bgColor: "#9f211f",
    lastWinner: null,
    subs: null,
    donateEnabled: false,
    votingEnabled: false,
  });
  const [hasSeenVoteOptions, setHasSeenVoteOptions] = useState(false);

  const displayStateRef = useRef(displayState);
  const hideTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    displayStateRef.current = displayState;
  }, [displayState]);

  useEffect(() => {
    const poll = async () => {
      try {
        const res = await fetch("/mod/status");
        if (!res.ok) return;
        const data = (await res.json()) as ModStatus;

        if (data.vote_options.length > 0) {
          setHasSeenVoteOptions(true);
        }

        const subs = data.twitch_subs ?? null;
        const donateEnabled = data.donateEnabled === true;
        const votingEnabled = data.voting_enabled === true;

        if (data.voting_enabled && data.vote_options.length > 0) {
          if (hideTimerRef.current !== null) {
            clearTimeout(hideTimerRef.current);
            hideTimerRef.current = null;
          }
          const current = displayStateRef.current;
          const newMode: DisplayMode =
            current.mode === "hidden" || current.mode === "hiding"
              ? "entering"
              : "voting";
          setDisplayState({
            mode: newMode,
            options: data.vote_options,
            totalVotes: data.total_votes,
            totalVotesLabel: data.total_votes_label ?? "Total votes: %d",
            bgColor: data.vote_background_color,
            lastWinner: data.last_winner,
            subs,
            donateEnabled,
            votingEnabled,
          });
        } else if (!data.voting_enabled && data.vote_options.length > 0) {
          const current = displayStateRef.current;
          if (
            (current.mode === "entering" || current.mode === "voting") &&
            hideTimerRef.current === null
          ) {
            setDisplayState((prev) => ({
              ...prev,
              mode: "results",
              options: data.vote_options,
              totalVotes: data.total_votes,
              totalVotesLabel: data.total_votes_label ?? "Total votes: %d",
              bgColor: data.vote_background_color,
              lastWinner: data.last_winner,
              subs,
              donateEnabled,
              votingEnabled,
            }));
            hideTimerRef.current = setTimeout(() => {
              setDisplayState((prev) => ({ ...prev, mode: "hiding" }));
              hideTimerRef.current = null;
            }, RESULTS_DURATION_MS);
          } else if (current.mode === "results" || current.mode === "hiding") {
            setDisplayState((prev) => ({
              ...prev,
              options: data.vote_options,
              totalVotes: data.total_votes,
              totalVotesLabel: data.total_votes_label ?? "Total votes: %d",
              bgColor: data.vote_background_color,
              lastWinner: data.last_winner,
              subs,
              donateEnabled,
              votingEnabled,
            }));
          } else {
            setDisplayState((prev) => ({
              ...prev,
              subs,
              donateEnabled,
              votingEnabled,
            }));
          }
        } else {
          setDisplayState((prev) => ({
            ...prev,
            subs,
            donateEnabled,
            votingEnabled,
          }));
        }
      } catch {
        // ignore network errors
      }
    };

    const interval = setInterval(poll, 1000);
    void poll();

    return () => {
      clearInterval(interval);
      if (hideTimerRef.current !== null) clearTimeout(hideTimerRef.current);
    };
  }, []);

  const {
    mode,
    options,
    totalVotes,
    totalVotesLabel,
    bgColor,
    lastWinner,
    subs,
    votingEnabled,
  } = displayState;

  const subsEnabled = subs?.enabled === true;
  const subsVisible = subsEnabled && subs?.show_in_obs === true;
  const subsLine = subsVisible && subs
    ? `Twitch Subs: ${subs.current}/${subs.threshold}`
    : null;
  const idleSecondLine = subsEnabled && !votingEnabled
    ? "Waiting for mod start"
    : "Waiting for vote";

  if (!hasSeenVoteOptions && mode === "hidden" && options.length === 0) {
    if (subsVisible && subsLine) {
      return (
        <main className="overlay overlay--idle">
          <div className="idle-line">{subsLine}</div>
        </main>
      );
    }
    return (
      <main className="overlay overlay--idle">
        <div className="idle-line">Chaos Mod OBS is working</div>
        <div className="idle-line">{idleSecondLine}</div>
      </main>
    );
  }

  if (mode === "hidden" || options.length === 0) {
    if (subsVisible && subsLine) {
      return (
        <main className="overlay overlay--idle">
          <div className="idle-line">{subsLine}</div>
        </main>
      );
    }
    return null;
  }

  const isResults = mode === "results" || mode === "hiding";

  const overlayClass =
    mode === "entering"
      ? "overlay overlay--entering"
      : mode === "hiding"
        ? "overlay overlay--hiding"
        : "overlay";

  const handleAnimationEnd = () => {
    if (mode === "entering") {
      setDisplayState((prev) => ({ ...prev, mode: "voting" }));
    } else if (mode === "hiding") {
      setDisplayState((prev) => ({ ...prev, mode: "hidden" }));
    }
  };

  return (
    <main className={overlayClass} onAnimationEnd={handleAnimationEnd}>
      <div className="total-votes-row">
        <div className="total-votes">{totalVotesLabel.replace("%d", formatTotalVotes(totalVotes))}</div>
        {subsVisible && subsLine && (
          <div className="twitch-subs-inline">{subsLine}</div>
        )}
      </div>
      <div className="options">
        {options.map((opt) => {
          const barWidth = getBarWidth(opt.votes, options);
          const opacity =
            isResults && lastWinner !== null
              ? opt.effect_id === lastWinner
                ? 1
                : 0.5
              : 1;
          const showDuration =
            !opt.hidden && typeof opt.duration === "number";
          const displayedName = showDuration
            ? `${opt.effect_name} (${opt.duration}s)`
            : opt.effect_name;

          return (
            <div key={opt.effect_id} className="option" style={{ opacity }}>
              <div className="option-bar">
                <div className="option-bar-bg" />
                <div
                  className="option-bar-fg"
                  style={{ width: barWidth, backgroundColor: bgColor }}
                />
                <div className="option-content">
                  <span className="option-index">{opt.index}</span>
                  <OptionName text={displayedName} />
                  {opt.votes !== undefined && (
                    <span className="option-votes">{formatOptionVotes(opt.votes)}</span>
                  )}
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </main>
  );
}
