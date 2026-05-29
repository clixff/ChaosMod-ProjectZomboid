import { useEffect, useState, type ReactNode } from "react";
import { Link } from "@tanstack/react-router";
import { ArrowRight, ChevronDown, Download } from "lucide-react";
import steamLogo from "../assets/steam_logo.webp";
import githubLogo from "../assets/github_logo.webp";
import { VERSION, buildDownloadUrl } from "../constants.ts";

const STEAM_WORKSHOP_URL =
  "https://steamcommunity.com/sharedfiles/filedetails/?id=3717082142";
const GITHUB_URL = "https://github.com/clixff/ChaosMod-ProjectZomboid";
const DASHBOARD_URL = "http://127.0.0.1:3959/dashboard";

interface FaqItem {
  question: string;
  answer: ReactNode;
}

const FAQ_ITEMS: FaqItem[] = [
  {
    question: "How to install the StreamerApp?",
    answer: (
      <ol className="faq-answer-list">
        <li>Install the mod first.</li>
        <li>
          Extract <strong>ZomboidStreamerApp.exe</strong> from the archive to any
          folder and launch it.
        </li>
        <li>
          Wait until the dashboard opens in your browser or open it manually:{" "}
          <a href={DASHBOARD_URL} target="_blank" rel="noreferrer">
            Local Dashboard
          </a>
        </li>
      </ol>
    ),
  },
];

function Faq() {
  const [openIndex, setOpenIndex] = useState<number | null>(null);

  return (
    <div className="faq">
      <h2 className="faq-title">FAQ</h2>
      <ul className="faq-list">
        {FAQ_ITEMS.map((item, index) => {
          const isOpen = openIndex === index;
          return (
            <li key={item.question} className="faq-item">
              <button
                type="button"
                className="faq-question"
                aria-expanded={isOpen}
                onClick={() => setOpenIndex(isOpen ? null : index)}
              >
                <span>{item.question}</span>
                <ChevronDown
                  size={18}
                  className={`faq-chevron${isOpen ? " faq-chevron--open" : ""}`}
                  aria-hidden="true"
                />
              </button>
              {isOpen && <div className="faq-answer">{item.answer}</div>}
            </li>
          );
        })}
      </ul>
    </div>
  );
}

// Kick off the zip download without navigating away from the page.
function triggerDownload() {
  const link = document.createElement("a");
  link.href = buildDownloadUrl(VERSION);
  link.download = "";
  document.body.appendChild(link);
  link.click();
  link.remove();
}

// Trigger the zip download in the background when the page is opened with
// ?download (e.g. via the /download redirect), then strip the query param so a
// refresh doesn't download again. Returns true while the download toast shows.
function useBackgroundDownload() {
  const [downloadStarted, setDownloadStarted] = useState(() =>
    new URLSearchParams(window.location.search).has("download"),
  );

  useEffect(() => {
    if (!downloadStarted) return;

    triggerDownload();

    const params = new URLSearchParams(window.location.search);
    params.delete("download");
    const query = params.toString();
    window.history.replaceState(
      null,
      "",
      `${window.location.pathname}${query ? `?${query}` : ""}`,
    );

    const timer = setTimeout(() => setDownloadStarted(false), 6000);
    return () => clearTimeout(timer);
  }, [downloadStarted]);

  return downloadStarted;
}

export function LandingPage() {
  const downloadStarted = useBackgroundDownload();

  return (
    <section className="landing">
      {downloadStarted ? (
        <div className="toast toast--top" role="status">
          <Download size={14} />
          <span>Your download has started — check your browser downloads.</span>
        </div>
      ) : null}

      <div className="landing-inner">
        <h1 className="landing-title">
          Chaos<span className="landing-title-accent">Mod</span>
        </h1>

        <div className="landing-divider" aria-hidden="true" />

        <p className="landing-tagline">
          Mod for Project Zomboid that adds 400+ random effects and Twitch &
          YouTube integration to the game
        </p>

        <div className="landing-download-row">
          <button
            type="button"
            className="landing-cta landing-cta--effects"
            onClick={triggerDownload}
          >
            <Download size={14} className="landing-download-icon" />
            <span>Download Mod + StreamerApp v{VERSION}</span>
          </button>
        </div>

        <div className="landing-cta-row">
          <a
            className="landing-cta landing-cta--steam"
            href={STEAM_WORKSHOP_URL}
            target="_blank"
            rel="noreferrer"
          >
            <img
              src={steamLogo}
              alt=""
              className="landing-cta-logo"
              aria-hidden="true"
            />
            <span>Open on Steam</span>
          </a>

          <a
            className="landing-cta landing-cta--github"
            href={GITHUB_URL}
            target="_blank"
            rel="noreferrer"
          >
            <img
              src={githubLogo}
              alt=""
              className="landing-cta-logo"
              aria-hidden="true"
            />
            <span>Open on GitHub</span>
          </a>

          <Link to="/effects" className="landing-cta landing-cta--effects-alt">
            <ArrowRight size={14} className="landing-cta-icon" />
            <span>Effects List</span>
          </Link>
        </div>

        <Faq />
      </div>
    </section>
  );
}
