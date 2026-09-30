import { useState } from 'react';
import Modal from './Modal';
import { patientsApi } from '../api/services';

const empty = {
  name: '',
  age: '',
  gender: 'female',
  contact: '',
  village: '',
  address: '',
  occupation: '',
  height: '',
  weight: '',
};

export default function PatientFormModal({ patient, onClose, onSaved }) {
  const isEdit = Boolean(patient);
  const [form, setForm] = useState(
    isEdit
      ? {
          name: patient.name || '',
          age: patient.age ?? '',
          gender: patient.gender || 'female',
          contact: patient.contact || '',
          village: patient.village || '',
          address: patient.address || '',
          occupation: patient.occupation || '',
          height: patient.height ?? '',
          weight: patient.weight ?? '',
        }
      : empty
  );
  const [error, setError] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const handleChange = (e) => setForm({ ...form, [e.target.name]: e.target.value });

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setSubmitting(true);
    try {
      const payload = {
        name: form.name.trim(),
        age: Number(form.age),
        gender: form.gender,
        contact: form.contact.trim() || undefined,
        village: form.village.trim() || undefined,
        address: form.address.trim() || undefined,
        occupation: form.occupation.trim() || undefined,
        height: form.height ? Number(form.height) : undefined,
        weight: form.weight ? Number(form.weight) : undefined,
      };
      if (isEdit) {
        const res = await patientsApi.update(patient.id, payload);
        onSaved(res.data);
      } else {
        const res = await patientsApi.create(payload);
        onSaved(res.data);
      }
    } catch (err) {
      const apiErrors = err.response?.data?.errors;
      setError(apiErrors?.[0]?.message || err.response?.data?.message || 'Could not save patient.');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <Modal
      title={isEdit ? 'Edit patient' : 'Add patient'}
      subtitle={isEdit ? 'Update this patient\u2019s record.' : 'Register a new patient for screening.'}
      onClose={onClose}
      width="620px"
      footer={
        <>
          <button type="button" className="btn btn-ghost" onClick={onClose}>Cancel</button>
          <button type="submit" form="patient-form" className="btn btn-primary" disabled={submitting}>
            {submitting ? 'Saving\u2026' : isEdit ? 'Save changes' : 'Add patient'}
          </button>
        </>
      }
    >
      <form id="patient-form" onSubmit={handleSubmit} className="patient-form">
        {error && <div className="banner banner-error">{error}</div>}

        <div className="form-section">
          <span className="form-section__label">Basic details</span>
          <div className="field">
            <label>Full name</label>
            <input name="name" value={form.name} onChange={handleChange} required autoFocus />
          </div>
          <div className="form-grid">
            <div className="field">
              <label>Age</label>
              <input name="age" type="number" min="0" max="150" value={form.age} onChange={handleChange} required />
            </div>
            <div className="field">
              <label>Gender</label>
              <select name="gender" value={form.gender} onChange={handleChange}>
                <option value="female">Female</option>
                <option value="male">Male</option>
                <option value="other">Other</option>
              </select>
            </div>
          </div>
        </div>

        <div className="form-section">
          <span className="form-section__label">Contact &amp; location</span>
          <div className="form-grid">
            <div className="field">
              <label>Contact number</label>
              <input name="contact" value={form.contact} onChange={handleChange} placeholder="9876543210" />
            </div>
            <div className="field">
              <label>Village</label>
              <input name="village" value={form.village} onChange={handleChange} placeholder="Tawang" />
            </div>
          </div>
          <div className="field">
            <label>Address</label>
            <input name="address" value={form.address} onChange={handleChange} />
          </div>
        </div>

        <div className="form-section">
          <span className="form-section__label">Occupation &amp; physical stats</span>
          <div className="field">
            <label>Occupation</label>
            <input name="occupation" value={form.occupation} onChange={handleChange} placeholder="Farmer" />
          </div>
          <div className="form-grid">
            <div className="field">
              <label>Height (cm)</label>
              <input name="height" type="number" value={form.height} onChange={handleChange} />
            </div>
            <div className="field">
              <label>Weight (kg)</label>
              <input name="weight" type="number" value={form.weight} onChange={handleChange} />
            </div>
          </div>
        </div>
      </form>
    </Modal>
  );
}