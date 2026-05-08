import type { ReactNode } from "react";

interface SectionProps {
  title?: string;
  description?: string;
  children: ReactNode;
  id?: string;
  icon?: ReactNode;
}

export function Section({
  title,
  description,
  children,
  id,
  icon,
}: SectionProps) {
  return (
    <div className="section" id={id}>
      {title !== undefined && (
        <h3 className="section-title">
          {icon !== undefined && (
            <span className="section-title-icon">{icon}</span>
          )}
          {title}
        </h3>
      )}
      {description !== undefined && <p className="section-desc">{description}</p>}
      <div className="section-body">{children}</div>
    </div>
  );
}

interface FieldRowProps {
  label: string;
  hint?: string;
  children: ReactNode;
}

export function FieldRow({ label, hint, children }: FieldRowProps) {
  return (
    <div className="field-row">
      <div className="field">
        <span className="field-label">{label}</span>
        {hint !== undefined && <span className="field-hint">{hint}</span>}
      </div>
      <div>{children}</div>
    </div>
  );
}
