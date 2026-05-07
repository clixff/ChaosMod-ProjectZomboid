import { useCallback, useEffect, useState } from "react";
import { HomePage } from "./pages/HomePage.tsx";
import { ConfigPage } from "./pages/ConfigPage.tsx";
import { EffectsPage } from "./pages/EffectsPage.tsx";
import { Toast } from "./components/Toast.tsx";
import { ActivityFeed } from "./components/ActivityFeed.tsx";
import { getHomeStatus, type ActivityEvent } from "./api.ts";

type Page = "home" | "config" | "effects";

interface ToastState {
  id: number;
  message: string;
  isError: boolean;
}

export function App() {
  const [page, setPage] = useState<Page>("home");
  const [scrollTarget, setScrollTarget] = useState<string | null>(null);
  const [toast, setToast] = useState<ToastState | null>(null);
  const [activity, setActivity] = useState<ActivityEvent[]>([]);

  useEffect(() => {
    let cancelled = false;
    const tick = async () => {
      try {
        const status = await getHomeStatus();
        if (!cancelled) setActivity(status.recent_activity ?? []);
      } catch {
        // Silently ignore — the feed is best-effort.
      }
    };
    void tick();
    const id = setInterval(() => {
      void tick();
    }, 2000);
    return () => {
      cancelled = true;
      clearInterval(id);
    };
  }, []);

  const notify = useCallback((message: string, isError?: boolean) => {
    setToast({ id: Date.now(), message, isError: !!isError });
  }, []);

  const navigate = useCallback((nextPage: Page, target?: string) => {
    setPage(nextPage);
    setScrollTarget(target ?? null);
  }, []);

  return (
    <div className="layout">
      <aside className="sidebar">
        <div className="sidebar-title">
          ChaosMod
          <span className="sidebar-title-sub">Streamer Dashboard</span>
        </div>
        <button
          className={`nav-button${page === "home" ? " is-active" : ""}`}
          onClick={() => navigate("home")}
        >
          Home
        </button>
        <button
          className={`nav-button${page === "config" ? " is-active" : ""}`}
          onClick={() => navigate("config")}
        >
          Config
        </button>
        <button
          className={`nav-button${page === "effects" ? " is-active" : ""}`}
          onClick={() => navigate("effects")}
        >
          Effects
        </button>
      </aside>
      <main className="main">
        {page === "home" && (
          <>
            <h1 className="page-title">Home</h1>
            <p className="page-subtitle">
              Connect providers, configure OBS, and export effect data.
            </p>
            <HomePage onNotify={notify} onNavigate={navigate} />
          </>
        )}
        {page === "config" && (
          <>
            <h1 className="page-title">Config</h1>
            <p className="page-subtitle">
              Changes are saved automatically and reloaded by the mod.
            </p>
            <ConfigPage onNotify={notify} scrollTarget={scrollTarget} />
          </>
        )}
        {page === "effects" && (
          <>
            <h1 className="page-title">Effects</h1>
            <p className="page-subtitle">
              Toggle effects, adjust chances, and configure donation prices.
            </p>
            <EffectsPage onNotify={notify} />
          </>
        )}
      </main>
      <ActivityFeed events={activity} />
      {toast && (
        <Toast
          key={toast.id}
          message={toast.message}
          isError={toast.isError}
          onDismiss={() => setToast(null)}
        />
      )}
    </div>
  );
}
