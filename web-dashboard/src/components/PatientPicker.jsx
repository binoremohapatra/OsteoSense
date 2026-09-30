import { useEffect, useRef, useState } from 'react';
import { Search, X } from 'lucide-react';
import { patientsApi } from '../api/services';

export default function PatientPicker({ value, onChange }) {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState([]);
  const [open, setOpen] = useState(false);
  const boxRef = useRef(null);

  useEffect(() => {
    function onClickOutside(e) {
      if (boxRef.current && !boxRef.current.contains(e.target)) setOpen(false);
    }
    document.addEventListener('mousedown', onClickOutside);
    return () => document.removeEventListener('mousedown', onClickOutside);
  }, []);

  useEffect(() => {
    if (query.trim().length < 2) {
      setResults([]);
      return;
    }
    const handle = setTimeout(async () => {
      try {
        const res = await patientsApi.search(query.trim());
        setResults(res.data || []);
      } catch {
        setResults([]);
      }
    }, 250);
    return () => clearTimeout(handle);
  }, [query]);

  if (value) {
    return (
      <div className="patient-search__selected">
        <span>{value.name} &middot; {value.age}{value.gender?.[0]?.toUpperCase()} &middot; {value.village || 'No village on file'}</span>
        <button type="button" className="btn-icon" onClick={() => onChange(null)} aria-label="Clear patient">
          <X size={15} />
        </button>
      </div>
    );
  }

  return (
    <div className="patient-search" ref={boxRef}>
      <div className="field" style={{ position: 'relative' }}>
        <input
          type="text"
          placeholder="Search by patient name or village…"
          value={query}
          onChange={(e) => {
            setQuery(e.target.value);
            setOpen(true);
          }}
          onFocus={() => setOpen(true)}
        />
        <Search size={15} style={{ position: 'absolute', right: 12, top: 12, color: 'var(--text-tertiary)' }} />
      </div>
      {open && results.length > 0 && (
        <div className="patient-search__results">
          {results.map((p) => (
            <div
              key={p.id}
              className="patient-search__item"
              onClick={() => {
                onChange(p);
                setOpen(false);
              }}
            >
              <strong>{p.name}</strong> &middot; {p.age}{p.gender?.[0]?.toUpperCase()} &middot; {p.village || 'No village'}
            </div>
          ))}
        </div>
      )}
      {open && query.trim().length >= 2 && results.length === 0 && (
        <div className="patient-search__results">
          <div className="patient-search__item" style={{ color: 'var(--text-tertiary)', cursor: 'default' }}>
            No matching patients
          </div>
        </div>
      )}
    </div>
  );
}
