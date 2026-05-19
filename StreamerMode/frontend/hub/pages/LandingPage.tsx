import { Link } from "@tanstack/react-router";
import { ArrowRight } from "lucide-react";
import steamLogo from "../assets/steam_logo.webp";
import githubLogo from "../assets/github_logo.webp";

const STEAM_WORKSHOP_URL =
  "https://steamcommunity.com/sharedfiles/filedetails/?id=3717082142";
const GITHUB_URL = "https://github.com/clixff/ChaosMod-ProjectZomboid";

export function LandingPage() {
  return (
    <section className="landing">
      <div className="landing-inner">
        <h1 className="landing-title landing-anim-fade-up landing-anim-delay-1">
          Chaos<span className="landing-title-accent">Mod</span>
        </h1>

        <div
          className="landing-divider landing-anim-divider"
          aria-hidden="true"
        />

        <p className="landing-tagline landing-anim-fade-up landing-anim-delay-3">
          Mod for Project Zomboid that adds 300+ random effects and Twitch &
          YouTube integration to the game
        </p>

        <div className="landing-cta-row">
          <a
            className="landing-cta landing-cta--steam landing-anim-fade-up landing-anim-delay-4"
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
            className="landing-cta landing-cta--github landing-anim-fade-up landing-anim-delay-5"
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

          <Link
            to="/effects"
            className="landing-cta landing-cta--effects landing-anim-fade-up landing-anim-delay-6"
          >
            <ArrowRight size={14} className="landing-cta-icon" />
            <span>Effects List</span>
          </Link>
        </div>
      </div>
    </section>
  );
}
