import type { ReactNode } from "react";
import { Link, useRouterState } from "@tanstack/react-router";
import { LanguageSwitcher } from "./LanguageSwitcher.tsx";

const NAV_ITEMS = [{ to: "/effects", label: "Effects" }] as const;

export function AppLayout({ children }: { children: ReactNode }) {
  const pathname = useRouterState({ select: (s) => s.location.pathname });

  return (
    <div className="layout">
      <header className="topbar">
        <Link to="/" className="brand-link">
          <span className="brand-bar" aria-hidden="true" />
          <span className="brand-mark">
            Chaos<span className="brand-mark-accent">Mod</span>
          </span>
        </Link>
        <nav className="topbar-nav" aria-label="Primary navigation">
          {NAV_ITEMS.map((item) => {
            const active = pathname.startsWith(item.to);
            return (
              <Link
                key={item.to}
                to={item.to}
                className={`nav-link${active ? " is-active" : ""}`}
              >
                <span>{item.label}</span>
              </Link>
            );
          })}
        </nav>
        <div className="topbar-spacer" />
        <LanguageSwitcher />
      </header>

      <main className="main">{children}</main>
    </div>
  );
}
