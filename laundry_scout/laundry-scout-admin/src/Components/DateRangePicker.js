import React, { useEffect, useId, useRef, useState } from "react";
import "../Style/DatePicker.css";

/**
 * Accessible Date Range Picker
 * - Keyboard: Enter/Space toggles, Escape closes, Tab cycles inputs
 * - Screen readers: labeled inputs, button has aria-expanded, aria-controls
 * - Uses native `<input type="date">` for broad accessibility
 */
export default function DateRangePicker({
  startDate,
  endDate,
  onChangeStart,
  onChangeEnd,
  onApply,
  buttonClassName = "a-date-btn",
  formatLabel = (s, e) => (s && e ? `${new Date(s).toLocaleDateString()} - ${new Date(e).toLocaleDateString()}` : "Filter by Date Range"),
  align = "left", // left | right
}) {
  const [open, setOpen] = useState(false);
  const popoverId = useId();
  const btnRef = useRef(null);
  const popoverRef = useRef(null);

  useEffect(() => {
    const onDocClick = (e) => {
      if (!open) return;
      if (
        popoverRef.current &&
        !popoverRef.current.contains(e.target) &&
        btnRef.current &&
        !btnRef.current.contains(e.target)
      ) {
        setOpen(false);
      }
    };
    document.addEventListener("mousedown", onDocClick);
    return () => document.removeEventListener("mousedown", onDocClick);
  }, [open]);

  const onKeyDownButton = (e) => {
    if (e.key === "Enter" || e.key === " ") {
      e.preventDefault();
      setOpen((v) => !v);
    } else if (e.key === "Escape") {
      setOpen(false);
    }
  };

  const onKeyDownPopover = (e) => {
    if (e.key === "Escape") {
      setOpen(false);
      btnRef.current?.focus();
    }
  };

  return (
    <div className="date-range-container" style={{ position: "relative" }}>
      <button
        ref={btnRef}
        className={buttonClassName}
        aria-haspopup="dialog"
        aria-expanded={open}
        aria-controls={popoverId}
        onClick={() => setOpen((v) => !v)}
        onKeyDown={onKeyDownButton}
      >
        {formatLabel(startDate, endDate)}
      </button>
      {open && (
        <div
          id={popoverId}
          ref={popoverRef}
          role="dialog"
          aria-label="Select date range"
          className="date-picker-popover"
          style={{ [align === "right" ? "right" : "left"]: 0 }}
          onKeyDown={onKeyDownPopover}
        >
          <div className="date-picker-input">
            <label htmlFor={`${popoverId}-start`}>Start Date</label>
            <input
              id={`${popoverId}-start`}
              type="date"
              value={startDate || ""}
              onChange={(e) => onChangeStart?.(e.target.value)}
            />
          </div>
          <div className="date-picker-input">
            <label htmlFor={`${popoverId}-end`}>End Date</label>
            <input
              id={`${popoverId}-end`}
              type="date"
              value={endDate || ""}
              onChange={(e) => onChangeEnd?.(e.target.value)}
            />
          </div>
          <button className="apply-btn" onClick={() => onApply?.()}>Apply Filter</button>
        </div>
      )}
    </div>
  );
}