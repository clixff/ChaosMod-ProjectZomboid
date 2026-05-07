import type { ChangeEvent } from "react";

interface CheckboxProps {
  checked: boolean;
  onChange: (checked: boolean) => void;
  label?: string;
  disabled?: boolean;
}

export function Checkbox({ checked, onChange, label, disabled }: CheckboxProps) {
  const handleChange = (e: ChangeEvent<HTMLInputElement>) => {
    onChange(e.target.checked);
  };
  return (
    <label className={`checkbox${disabled ? " is-disabled" : ""}`}>
      <input
        type="checkbox"
        checked={checked}
        onChange={handleChange}
        disabled={disabled}
      />
      <span className="checkbox-box">
        <svg viewBox="0 0 24 24" className="checkbox-check">
          <polyline points="4 12 10 18 20 6" />
        </svg>
      </span>
      {label !== undefined && <span className="checkbox-label">{label}</span>}
    </label>
  );
}
