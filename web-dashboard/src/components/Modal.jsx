import { useLayoutEffect, useRef } from 'react';
import { X } from 'lucide-react';

export default function Modal({ title, subtitle, onClose, children, footer, width }) {
  const cardRef = useRef(null);
  const bodyRef = useRef(null);

  // Lock body scroll while the modal is open, and restore on close/unmount.
  useLayoutEffect(() => {
    const { overflow } = document.body.style;
    document.body.style.overflow = 'hidden';
    return () => {
      document.body.style.overflow = overflow;
    };
  }, []);

  // Force the scrollable body to the top BEFORE the browser paints, so the
  // dialog always opens on its first section instead of wherever a native
  // autofocus/scrollIntoView call happened to land.
  useLayoutEffect(() => {
    if (bodyRef.current) bodyRef.current.scrollTop = 0;
    if (cardRef.current && !cardRef.current.contains(document.activeElement)) {
      cardRef.current.focus({ preventScroll: true });
    }
  }, []);

  useLayoutEffect(() => {
    const handleKeyDown = (e) => {
      if (e.key === 'Escape') onClose();
    };
    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, [onClose]);

  return (
    <div
      className="modal-overlay"
      onMouseDown={(e) => {
        if (e.target === e.currentTarget) onClose();
      }}
    >
      <div
        className="modal-card"
        role="dialog"
        aria-modal="true"
        aria-label={title}
        tabIndex={-1}
        ref={cardRef}
        style={width ? { '--modal-width': width } : undefined}
      >
        <div className="modal-head">
          <div className="modal-head__text">
            <h3>{title}</h3>
            {subtitle && <p className="modal-head__subtitle">{subtitle}</p>}
          </div>
          <button type="button" className="btn-icon modal-close" onClick={onClose} aria-label="Close">
            <X size={18} />
          </button>
        </div>
        <div className="modal-body" ref={bodyRef}>{children}</div>
        {footer && <div className="modal-foot">{footer}</div>}
      </div>
    </div>
  );
}