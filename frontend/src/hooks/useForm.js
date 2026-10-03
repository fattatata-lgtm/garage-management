import { useState, useCallback } from 'react';

// State form sederhana: bind(k) untuk input, load(values) untuk mengisi data edit,
// reset() mengembalikan ke nilai awal (atau nilai terakhir yang di-load saat edit).
export default function useForm(initial) {
  const [base, setBase] = useState(initial);
  const [form, setForm] = useState(initial);

  const bind = (k) => (e) => {
    const v = e.target.type === 'checkbox' ? e.target.checked : e.target.value;
    setForm((f) => ({ ...f, [k]: v }));
  };
  const load = useCallback((values) => { setBase(values); setForm(values); }, []);
  const reset = () => setForm(base);

  return { form, setForm, bind, load, reset };
}

export function errMsg(err, fallback) {
  return err?.response?.data?.message || fallback;
}
