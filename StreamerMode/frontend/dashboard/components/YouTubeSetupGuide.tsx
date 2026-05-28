import { useState } from "react";
import type { ReactNode } from "react";
import {
  ChevronDown,
  ChevronUp,
  ChevronLeft,
  ChevronRight,
  ExternalLink as ExternalLinkIcon,
} from "lucide-react";
import step3Image from "../assets/youtube-guide/step3-create-project.png";
import step4Image from "../assets/youtube-guide/step4-enable-api.png";
import step5Image1 from "../assets/youtube-guide/step5-1-create-credentials.png";
import step5Image2 from "../assets/youtube-guide/step5-2-select-api-key.png";
import step5Image3 from "../assets/youtube-guide/step5-3-api-restriction.png";
import step5Image4 from "../assets/youtube-guide/step5-4-restriction-ok.png";
import step5Image5 from "../assets/youtube-guide/step5-5-application-restrictions.png";
import step5Image6 from "../assets/youtube-guide/step5-6-copy-key.png";

function ConsoleLinkButton({ href, label }: { href: string; label: string }) {
  return (
    <a
      href={href}
      target="_blank"
      rel="noopener noreferrer"
      className="yt-guide-link-btn"
    >
      Open {label}
      <ExternalLinkIcon size={14} aria-hidden="true" />
    </a>
  );
}

function GuideImage({ src, alt }: { src: string; alt: string }) {
  return (
    <a
      href={src}
      target="_blank"
      rel="noopener noreferrer"
      className="yt-guide-image-link"
    >
      <img src={src} alt={alt} className="yt-guide-image" />
    </a>
  );
}

interface GuidePage {
  title: string;
  body: ReactNode;
}

const PAGES: GuidePage[] = [
  {
    title: "Notes",
    body: (
      <>
        <ul>
          <li>Don't display your API key and don't give it to anyone.</li>
          <li>
            The API key doesn't have access to your Google or YouTube account,
            only public YouTube data.
          </li>
        </ul>
        <p>
          You only need a simple <strong>API key</strong> from Google Cloud
          Console, not an OAuth key or Desktop / Web-App key.
        </p>
      </>
    ),
  },
  {
    title: "1. Open Google Cloud Console",
    body: (
      <>
        <p>Open Google Cloud Console and sign in with your Google account.</p>
        <ConsoleLinkButton
          href="https://console.cloud.google.com/welcome"
          label="Google Cloud Console"
        />
      </>
    ),
  },
  {
    title: "2. Create a New Project",
    body: (
      <>
        <p>Go to Google Console → Project Create.</p>
        <ConsoleLinkButton
          href="https://console.cloud.google.com/projectcreate"
          label="Project Create"
        />
        <ol>
          <li>
            Enter any project name, for example:
            <pre>
              <code>ProjectZomboidChaos My Nickname</code>
            </pre>
          </li>
          <li>
            Click <strong>Create</strong>.
          </li>
          <li>Make sure the new project is selected.</li>
        </ol>
        <GuideImage src={step3Image} alt="Create a new project in Google Cloud Console" />
      </>
    ),
  },
  {
    title: "3. Enable YouTube Data API v3",
    body: (
      <>
        <p>Go to Google Console → API Library → YouTube Data API v3.</p>
        <ConsoleLinkButton
          href="https://console.cloud.google.com/apis/library/youtube.googleapis.com"
          label="YouTube Data API v3"
        />
        <ol>
          <li>Make sure your new project is selected.</li>
          <li>
            Click <strong>Enable</strong>.
          </li>
        </ol>
        <GuideImage src={step4Image} alt="Enable YouTube Data API v3" />
      </>
    ),
  },
  {
    title: "4. Create an API Key",
    body: (
      <>
        <p>Go to Google Console → APIs &amp; Services → Credentials.</p>
        <ConsoleLinkButton
          href="https://console.cloud.google.com/apis/credentials"
          label="Credentials"
        />
        <ol>
          <li>
            Click <strong>Create credentials</strong>.
          </li>
          <li>
            Select <strong>API key</strong>.
          </li>
        </ol>
        <GuideImage src={step5Image1} alt="Create credentials button" />
        <GuideImage src={step5Image2} alt="Select API key from the dropdown" />
        <ol start={3}>
          <li>
            Use any name for this key, for example "ChaosMod API Key".
          </li>
          <li>
            In <strong>Selected API Restrictions</strong> select{" "}
            <strong>YouTube Data API v3</strong> and press <strong>OK</strong>.
          </li>
        </ol>
        <GuideImage src={step5Image3} alt="Selected API restrictions list" />
        <GuideImage src={step5Image4} alt="Selected API restriction confirmation" />
        <ol start={5}>
          <li>
            Select <strong>Application restrictions — None</strong> and press{" "}
            <strong>Create</strong>.
          </li>
        </ol>
        <GuideImage src={step5Image5} alt="Application restrictions set to None" />
        <ol start={6}>
          <li>Copy the generated API key.</li>
        </ol>
        <GuideImage src={step5Image6} alt="Copy the generated API key" />
      </>
    ),
  },
  {
    title: "5. Add the Key to the Mod",
    body: (
      <p>
        Return to the ChaosMod Streamer App dashboard and paste your API key
        into the field below this guide.
      </p>
    ),
  },
  {
    title: "6. Removing the API Key",
    body: (
      <p>
        You can remove the API key in Google Cloud Console after you finish
        playing with this mod on YouTube Live.
      </p>
    ),
  },
  {
    title: "Important Notes",
    body: (
      <>
        <p>
          Do <strong>not</strong> share your API key publicly.
        </p>
        <p>
          You do <strong>not</strong> need:
        </p>
        <pre>
          <code>
            {`OAuth Client ID
OAuth Client Secret
OAuth Consent Screen
Service Account`}
          </code>
        </pre>
        <p>Only create:</p>
        <pre>
          <code>API key</code>
        </pre>
      </>
    ),
  },
  {
    title: "Troubleshooting",
    body: (
      <>
        <h5>The API key does not work</h5>
        <p>Check that:</p>
        <ol>
          <li>
            You enabled <strong>YouTube Data API v3</strong>.
          </li>
          <li>
            You selected the same Google Cloud project where the API key was
            created.
          </li>
          <li>You copied the full API key without extra spaces.</li>
          <li>The key was not deleted or restricted incorrectly.</li>
        </ol>
        <h5>I reached the quota limit</h5>
        <p>
          YouTube Data API has daily quota limits. If the key stops working
          after many requests, wait until the quota resets, check the quota
          page in Google Cloud Console, or create a new project.
        </p>
      </>
    ),
  },
];

interface YouTubeSetupGuideProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function YouTubeSetupGuide({ open, onOpenChange }: YouTubeSetupGuideProps) {
  const [page, setPage] = useState(0);

  const current = PAGES[page];
  const isFirst = page === 0;
  const isLast = page === PAGES.length - 1;

  return (
    <div className="yt-guide">
      <button
        type="button"
        className="btn yt-guide-toggle"
        onClick={() => onOpenChange(!open)}
        aria-expanded={open}
      >
        {open ? "Hide setup instructions" : "Show setup instructions"}
        {open ? (
          <ChevronUp size={14} aria-hidden="true" />
        ) : (
          <ChevronDown size={14} aria-hidden="true" />
        )}
      </button>

      {open && (
        <div className="yt-guide-card">
          <div className="yt-guide-page">
            <h4 className="yt-guide-title">{current.title}</h4>
            <div className="yt-guide-body">{current.body}</div>
          </div>
          <div className="yt-guide-nav">
            <button
              type="button"
              className="btn yt-guide-back"
              onClick={() => setPage((p) => Math.max(0, p - 1))}
              disabled={isFirst}
            >
              <ChevronLeft size={14} aria-hidden="true" />
              Back
            </button>
            <span className="yt-guide-counter">
              Step {page + 1} of {PAGES.length}
            </span>
            <button
              type="button"
              className="btn btn--success yt-guide-next"
              onClick={() =>
                setPage((p) => Math.min(PAGES.length - 1, p + 1))
              }
              disabled={isLast}
            >
              Next
              <ChevronRight size={14} aria-hidden="true" />
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
