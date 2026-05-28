import type { ChangeEvent, CSSProperties, KeyboardEvent } from "react";
import { X } from "lucide-react";

interface TextInputProps {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  size?: "small" | "mid" | "full";
  type?: "text" | "color" | "password";
  style?: CSSProperties;
  onBlur?: () => void;
  onSubmit?: () => void;
  onClear?: () => void;
  noAutofill?: boolean;
}

export function TextInput({
  value,
  onChange,
  placeholder,
  size = "full",
  type = "text",
  style,
  onBlur,
  onSubmit,
  onClear,
  noAutofill,
}: TextInputProps) {
  const cls =
    size === "small" ? "input input--small" : size === "mid" ? "input input--mid" : "input";
  const handleChange = (e: ChangeEvent<HTMLInputElement>) => {
    onChange(e.target.value);
  };
  const handleKeyDown = (e: KeyboardEvent<HTMLInputElement>) => {
    if (e.key === "Enter" && onSubmit) {
      e.preventDefault();
      onSubmit();
    }
  };
  const noAutofillProps = noAutofill
    ? {
        autoComplete: "off",
        spellCheck: false,
        autoCorrect: "off",
        autoCapitalize: "off",
        "data-lpignore": "true",
        "data-1p-ignore": "true",
        "data-bwignore": "true",
        "data-form-type": "other",
      }
    : {};
  const input = (
    <input
      className={cls}
      type={type}
      value={value}
      onChange={handleChange}
      placeholder={placeholder}
      style={style}
      onBlur={onBlur}
      onKeyDown={handleKeyDown}
      {...noAutofillProps}
    />
  );
  if (!onClear) return input;
  return (
    <span className="input-wrap">
      {input}
      {value.length > 0 && (
        <button
          type="button"
          className="input-clear"
          aria-label="Clear"
          title="Clear"
          onMouseDown={(e) => e.preventDefault()}
          onClick={onClear}
        >
          <X size={14} aria-hidden="true" />
        </button>
      )}
    </span>
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
