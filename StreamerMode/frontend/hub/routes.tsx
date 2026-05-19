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
  notFoundRoute,
]);
