import { useState, useEffect, useRef } from "react";

interface VoteOption {
  effect_id: string;
  index: number;
  effect_name: string;
  votes: number | undefined;
}

interface ModStatus {
  voting_enabled: boolean;
  total_votes: number;
  total_votes_label: string;
  vote_background_color: string;
  last_winner: string | null;
  vote_options: VoteOption[];
}

type DisplayMode = "hidden" | "entering" | "voting" | "results" | "hiding";

interface DisplayState {
  mode: DisplayMode;
  options: VoteOption[];
  totalVotes: number;
  totalVotesLabel: string;
  bgColor: string;
  lastWinner: string | null;
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

function getNameFontSize(name: string): string {
  if (name.length > 38) return "11px";
  if (name.length > 30) return "13px";
  return "15px";
}

export function App() {
  const [displayState, setDisplayState] = useState<DisplayState>({
    mode: "hidden",
    options: [],
    totalVotes: 0,
    totalVotesLabel: "Total votes: %d",
    bgColor: "#9f211f",
    lastWinner: null,
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
            }));
          }
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

  const { mode, options, totalVotes, totalVotesLabel, bgColor, lastWinner } = displayState;

  if (!hasSeenVoteOptions && mode === "hidden" && options.length === 0) {
    return (
      <main className="overlay overlay--idle">
        <div className="idle-line">Chaos Mod OBS is working</div>
        <div className="idle-line">Waiting for vote</div>
      </main>
    );
  }

  if (mode === "hidden" || options.length === 0) return null;

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
      <div className="total-votes">{totalVotesLabel.replace("%d", formatTotalVotes(totalVotes))}</div>
      <div className="options">
        {options.map((opt) => {
          const barWidth = getBarWidth(opt.votes, options);
          const opacity =
            isResults && lastWinner !== null
              ? opt.effect_id === lastWinner
                ? 1
                : 0.5
              : 1;

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
                  <span
                    className="option-name"
                    style={{ fontSize: getNameFontSize(opt.effect_name) }}
                  >
                    {opt.effect_name}
                  </span>
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
