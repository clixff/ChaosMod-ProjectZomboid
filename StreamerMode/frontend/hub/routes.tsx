import {
  Outlet,
  createRootRoute,
  createRoute,
  redirect,
} from "@tanstack/react-router";
import { AppLayout } from "./layout/AppLayout.tsx";
import { LandingPage } from "./pages/LandingPage.tsx";
import { EffectsPage } from "./pages/EffectsPage.tsx";

const rootRoute = createRootRoute({
  component: () => (
    <AppLayout>
      <Outlet />
    </AppLayout>
  ),
});

const indexRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: "/",
  component: LandingPage,
});

const effectsRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: "/effects",
  component: EffectsPage,
});

// /e/:name → /effects?c=:name, preserving every other query param.
const sharedConfigRedirectRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: "/e/$name",
  beforeLoad: ({ params }) => {
    const search: Record<string, string> = { c: params.name };
    if (typeof window !== "undefined") {
      const current = new URLSearchParams(window.location.search);
      for (const [key, value] of current.entries()) {
        if (key === "c") continue;
        search[key] = value;
      }
    }
    throw redirect({ to: "/effects", search });
  },
  component: () => null,
});

// Catch-all: any unknown path redirects to /effects.
const notFoundRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: "$",
  beforeLoad: () => {
    throw redirect({ to: "/effects" });
  },
  component: () => null,
});

export const routeTree = rootRoute.addChildren([
  indexRoute,
  effectsRoute,
  sharedConfigRedirectRoute,
  notFoundRoute,
]);
