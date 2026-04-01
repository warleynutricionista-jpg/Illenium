(() => {
  const RESOURCE = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'illenium-appearance';
  const OPEN_EVENTS = new Set(['appearance_display']);
  const CLOSE_EVENTS = new Set(['appearance_hide']);

  const state = {
    nuiVisible: false,
    interceptingSave: false,
    pendingSave: null,
    identityEnabled: true,
  };

  const fields = {
    firstname: '', lastname: '', dob: '', sex: 'M', nationality: ''
  };

  const el = document.createElement('div');
  el.id = 'ia-modern-identity';
  el.innerHTML = `
    <section class="ia-panel">
      <h2 class="ia-title">Identidade do Personagem</h2>
      <p class="ia-subtitle">Visual inspirado em kIdentity com persistência compatível com illenium-appearance.</p>
      <div class="ia-grid">
        <label>Nome<input id="ia-firstname" maxlength="24" placeholder="Nome" /></label>
        <label>Sobrenome<input id="ia-lastname" maxlength="24" placeholder="Sobrenome" /></label>
        <label>Data de nascimento<input id="ia-dob" type="date" /></label>
        <label>Sexo
          <select id="ia-sex">
            <option value="M">Masculino</option>
            <option value="F">Feminino</option>
          </select>
        </label>
        <label class="ia-full">Nacionalidade<input id="ia-nationality" maxlength="24" placeholder="Nacionalidade" /></label>
      </div>
      <div class="ia-actions">
        <button type="button" class="ia-cancel" id="ia-cancel">Cancelar</button>
        <button type="button" class="ia-confirm" id="ia-confirm">Confirmar e Salvar</button>
      </div>
      <div class="ia-error" id="ia-error"></div>
    </section>
  `;

  const get = (id) => el.querySelector(`#${id}`);
  const errorEl = () => get('ia-error');

  const send = async (eventName, data = {}) => {
    const response = await fetch(`https://${RESOURCE}/${eventName}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data),
    });
    return response.json().catch(() => ({}));
  };

  const setOpen = (isOpen) => {
    el.classList.toggle('ia-open', isOpen);
    if (!isOpen) {
      errorEl().textContent = '';
    }
  };

  const validate = () => {
    fields.firstname = get('ia-firstname').value.trim();
    fields.lastname = get('ia-lastname').value.trim();
    fields.dob = get('ia-dob').value;
    fields.sex = get('ia-sex').value;
    fields.nationality = get('ia-nationality').value.trim();

    if (!fields.firstname || !fields.lastname || !fields.dob) {
      return 'Preencha nome, sobrenome e data de nascimento.';
    }

    return '';
  };

  const submitSave = async () => {
    const message = validate();
    if (message) {
      errorEl().textContent = message;
      return;
    }

    try {
      await send('appearance_save_identity', fields);
      const originalPayload = state.pendingSave;
      state.pendingSave = null;
      state.interceptingSave = false;
      setOpen(false);
      await send('appearance_save', originalPayload);
    } catch (err) {
      errorEl().textContent = 'Falha ao salvar. Tente novamente.';
      console.error('[illenium-appearance] identity bridge save failed', err);
    }
  };

  const cancelSave = async () => {
    state.pendingSave = null;
    state.interceptingSave = false;
    setOpen(false);
  };

  const bootstrap = async () => {
    document.body.appendChild(el);
    get('ia-confirm').addEventListener('click', submitSave);
    get('ia-cancel').addEventListener('click', cancelSave);

    try {
      const cfg = await send('appearance_get_modern_ui_config', {});
      state.identityEnabled = cfg?.identityEnabled !== false;
    } catch (e) {
      state.identityEnabled = true;
    }
  };

  const nativeFetch = window.fetch.bind(window);
  window.fetch = async (input, init = undefined) => {
    try {
      const url = typeof input === 'string' ? input : input?.url || '';
      if (
        state.identityEnabled &&
        state.nuiVisible &&
        !state.interceptingSave &&
        typeof url === 'string' &&
        /\/appearance_save$/.test(url)
      ) {
        state.interceptingSave = true;
        state.pendingSave = JSON.parse(init?.body || '{}');
        setOpen(true);

        return new Response(JSON.stringify(1), {
          status: 200,
          headers: { 'Content-Type': 'application/json' },
        });
      }
    } catch (err) {
      console.error('[illenium-appearance] modern bridge fetch intercept failed', err);
    }

    return nativeFetch(input, init);
  };

  window.addEventListener('message', (event) => {
    const type = event?.data?.type;
    if (OPEN_EVENTS.has(type)) {
      state.nuiVisible = true;
    }
    if (CLOSE_EVENTS.has(type)) {
      state.nuiVisible = false;
      state.interceptingSave = false;
      state.pendingSave = null;
      setOpen(false);
    }
  });

  window.addEventListener('error', (event) => {
    console.error('[illenium-appearance] NUI JS error captured', event.error || event.message);
  });

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', bootstrap, { once: true });
  } else {
    bootstrap();
  }
})();
