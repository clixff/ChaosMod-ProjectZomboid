import { useEffect } from "react";

interface ToastProps {
  message: string;
  isError?: boolean;
  onDismiss: () => void;
}

export function Toast({ message, isError, onDismiss }: ToastProps) {
  useEffect(() => {
    const t = setTimeout(onDismiss, 2500);
    return () => clearTimeout(t);
  }, [message, onDismiss]);
  return <div className={`toast${isError ? " is-error" : ""}`}>{message}</div>;
}
