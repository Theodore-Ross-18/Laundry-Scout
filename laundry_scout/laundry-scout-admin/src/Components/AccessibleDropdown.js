import React, { useEffect, useId, useRef, useState } from "react";
import styles from "../Style/AccessibleDropdown.module.css";

/**
 * AccessibleDropdown
 * - Keyboard: Enter/Space toggles, Escape closes, Arrow keys navigate
 * - Screen readers: aria-haspopup, aria-expanded, role=listbox/option, aria-selected
 * - Focus management: moves focus into menu on open
 */
export default function AccessibleDropdown({
  buttonClassName,
  selected,
  options = [], // array of strings or { label, value }
  onSelect,
  label = null, // button label; if null shows selected or placeholder
  placeholder = "All Transactions",
  align = "left", // left | right
}) {
  const [open, setOpen] = useState(false);
  const popoverId = useId();
  const btnRef = useRef(null);
  const menuRef = useRef(null);
  const [focusedIndex, setFocusedIndex] = useState(0);

  const normalized = options.map((opt) =>
    typeof opt === "string" ? { label: opt, value: opt } : opt
  );

  useEffect(() => {
    const onDocClick = (e) => {
      if (!open) return;
      if (
        menuRef.current && !menuRef.current.contains(e.target) &&
        btnRef.current && !btnRef.current.contains(e.target)
      ) {
        setOpen(false);
      }
    };
    document.addEventListener("mousedown", onDocClick);
    return () => document.removeEventListener("mousedown", onDocClick);
  }, [open]);

  useEffect(() => {
    if (open) {
      // focus first option
      const first = menuRef.current?.querySelector('[role="option"]');
      first?.focus();
      setFocusedIndex(0);
    }
  }, [open]);

  const onKeyDownButton = (e) => {
    if (e.key === "Enter" || e.key === " ") {
      e.preventDefault();
      setOpen((v) => !v);
    } else if (e.key === "ArrowDown") {
      e.preventDefault();
      setOpen(true);
    } else if (e.key === "Escape") {
      setOpen(false);
    }
  };

  const onKeyDownMenu = (e) => {
    if (e.key === "Escape") {
      setOpen(false);
      btnRef.current?.focus();
      return;
    }
    if (e.key === "ArrowDown") {
      e.preventDefault();
      setFocusedIndex((i) => Math.min(i + 1, normalized.length - 1));
      menuRef.current
        ?.querySelectorAll('[role="option"]')
        [Math.min(focusedIndex + 1, normalized.length - 1)]?.focus();
    }
    if (e.key === "ArrowUp") {
      e.preventDefault();
      setFocusedIndex((i) => Math.max(i - 1, 0));
      menuRef.current?.querySelectorAll('[role="option"]')[
        Math.max(focusedIndex - 1, 0)
      ]?.focus();
    }
  };

  return (
    <div className={styles.container}>
      <button
        ref={btnRef}
        className={buttonClassName}
        aria-haspopup="listbox"
        aria-expanded={open}
        aria-controls={popoverId}
        onClick={() => setOpen((v) => !v)}
        onKeyDown={onKeyDownButton}
      >
        {label ?? selected ?? placeholder}
      </button>
      {open && (
        <div
          id={popoverId}
          ref={menuRef}
          role="listbox"
          aria-label="Choose filter"
          className={styles.menu}
          style={{ [align === "right" ? "right" : "left"]: 0 }}
          onKeyDown={onKeyDownMenu}
        >
          {normalized.map((opt, idx) => (
            <button
              key={opt.value}
              role="option"
              aria-selected={selected === opt.value}
              tabIndex={idx === 0 ? 0 : -1}
              className={`${styles.option} ${selected === opt.value ? styles.active : ""}`}
              onClick={() => {
                onSelect?.(opt.value);
                setOpen(false);
                btnRef.current?.focus();
              }}
            >
              {opt.label}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}