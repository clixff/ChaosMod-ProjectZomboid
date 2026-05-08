import type { ChangeEvent, CSSProperties } from "react";

interface TextInputProps {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  size?: "small" | "mid" | "full";
  type?: "text" | "color" | "password";
  style?: CSSProperties;
}

export function TextInput({
  value,
  onChange,
  placeholder,
  size = "full",
  type = "text",
  style,
}: TextInputProps) {
  const cls =
    size === "small" ? "input input--small" : size === "mid" ? "input input--mid" : "input";
  const handleChange = (e: ChangeEvent<HTMLInputElement>) => {
    onChange(e.target.value);
  };
  return (
    <input
      className={cls}
      type={type}
      value={value}
      onChange={handleChange}
      placeholder={placeholder}
      style={style}
    />
  );
}

interface NumberInputProps {
  value: number;
  onChange: (value: number) => void;
  min?: number;
  max?: number;
  step?: number;
  size?: "small" | "mid" | "full";
}

export function NumberInput({
  value,
  onChange,
  min,
  max,
  step,
  size = "small",
}: NumberInputProps) {
  const cls =
    size === "small" ? "input input--small" : size === "mid" ? "input input--mid" : "input";
  const handleChange = (e: ChangeEvent<HTMLInputElement>) => {
    const raw = e.target.value;
    if (raw === "") {
      onChange(0);
      return;
    }
    const n = Number(raw);
    if (Number.isFinite(n)) onChange(n);
  };
  return (
    <input
      className={cls}
      type="number"
      value={value}
      onChange={handleChange}
      min={min}
      max={max}
      step={step}
    />
  );
}
