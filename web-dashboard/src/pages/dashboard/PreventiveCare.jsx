import { useEffect, useState } from 'react';
import { preventiveCareApi } from '../../api/services';
import Spinner from '../../components/Spinner';
import EmptyState from '../../components/EmptyState';
import './Dashboard.css';

const CATEGORIES = [
  { key: '', label: 'All' },
  { key: 'exercises', label: 'Exercises' },
  { key: 'diet', label: 'Diet' },
  { key: 'lifestyle', label: 'Lifestyle' },
];

export default function PreventiveCare() {
  const [category, setCategory] = useState('');
  const [lang, setLang] = useState('en');
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    const params = { lang };
    if (category) params.category = category;
    preventiveCareApi.list(params).then((res) => {
      setItems(res.data || []);
      setLoading(false);
    });
  }, [category, lang]);

  return (
    <div>
      <div className="page-head">
        <div>
          <h1>Preventive care</h1>
          <p>Hand this guidance to patients right after their screening.</p>
        </div>
      </div>

      <div className="filters-row" style={{ justifyContent: 'space-between' }}>
        <div className="tab-row" style={{ marginBottom: 0 }}>
          {CATEGORIES.map((c) => (
            <button key={c.key} className={`chip${category === c.key ? ' active' : ''}`} onClick={() => setCategory(c.key)}>
              {c.label}
            </button>
          ))}
        </div>
        <select value={lang} onChange={(e) => setLang(e.target.value)}>
          <option value="en">English</option>
          <option value="hi">हिन्दी</option>
        </select>
      </div>

      {loading ? (
        <Spinner />
      ) : items.length === 0 ? (
        <EmptyState title="No content yet" message="Run the seed script to populate preventive care content." />
      ) : (
        <div className="care-grid">
          {items.map((item) => (
            <div className="care-card" key={item.id}>
              <span className="care-card__cat">{item.category}</span>
              <h3>{item.title}</h3>
              <p>{item.content}</p>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
