(() => {
  const RESOURCE = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'illenium-appearance';
  const OPEN_EVENTS = new Set(['appearance_display']);
  const CLOSE_EVENTS = new Set(['appearance_hide']);

  const state = {
    nuiVisible: false,
    identityEnabled: true,
    appearanceReady: false,
    interceptSave: false,
    pendingAppearance: null,
    assets: {},
  };

  const fields = {
    firstname: '',
    lastname: '',
    dob: '',
    sex: 'M',
    nationality: '',
  };

  const nativeFetch = window.fetch.bind(window);

  const postNui = async (route, payload = {}) => {
    const response = await nativeFetch(`https://${RESOURCE}/${route}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(payload),
    });

    return response.json().catch(() => ({}));
  };

  const createIdentityOverlay = () => {
    const node = document.createElement('section');
    node.id = 'ia-modern-identity';
    node.innerHTML = `
      <div class="ia-backdrop"></div>
      <div class="ia-panel">
        <header class="ia-panel-header">
          <h2>Identidade do personagem</h2>
          <p>Fluxo inspirado em kIdentity, mantendo callbacks do illenium-appearance.</p>
        </header>
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
          <button type="button" data-action="cancel">Cancelar</button>
          <button type="button" class="ia-primary" data-action="confirm">Confirmar e salvar</button>
        </div>
        <p id="ia-error" class="ia-error"></p>
      </div>
    `;

    return node;
  };

  const createHudOverlay = () => {
    const node = document.createElement('section');
    node.id = 'ia-modern-hud';
    node.innerHTML = `
      <div class="ia-hud-card">
        <div class="ia-stepper">
          <div class="ia-step ia-step-active" data-step="identity">1. Identidade</div>
          <div class="ia-step" data-step="appearance">2. Aparência</div>
        </div>
        <div class="ia-hud-actions">
          <button type="button" data-cam="head">Rosto</button>
          <button type="button" data-cam="body">Corpo</button>
          <button type="button" data-turn="left">↺</button>
          <button type="button" data-turn="right">↻</button>
        </div>
      </div>
    `;
    return node;
  };

  const identityEl = createIdentityOverlay();
  const hudEl = createHudOverlay();

  const getById = (id) => identityEl.querySelector(`#${id}`);

  const setRootState = (enabled) => {
    document.body.classList.toggle('ia-modernized', enabled);
    hudEl.classList.toggle('ia-open', enabled);
  };

  const setIdentityOpen = (open) => {
    identityEl.classList.toggle('ia-open', open);
    if (!open) {
      getById('ia-error').textContent = '';
    }
  };

  const setStep = (step) => {
    hudEl.querySelectorAll('.ia-step').forEach((item) => {
      item.classList.toggle('ia-step-active', item.dataset.step === step);
    });
  };

  const readIdentityFields = () => {
    fields.firstname = getById('ia-firstname').value.trim();
    fields.lastname = getById('ia-lastname').value.trim();
    fields.dob = getById('ia-dob').value;
    fields.sex = getById('ia-sex').value;
    fields.nationality = getById('ia-nationality').value.trim();
    return fields;
  };

  const validateIdentity = () => {
    const data = readIdentityFields();
    if (!data.firstname || !data.lastname || !data.dob) {
      return 'Preencha nome, sobrenome e data de nascimento.';
    }
    return '';
  };

  const cancelIdentity = async () => {
    state.pendingAppearance = null;
    state.interceptSave = false;
    setIdentityOpen(false);
    await postNui('appearance_exit', {});
  };

  const confirmIdentity = async () => {
    const validationError = validateIdentity();
    if (validationError) {
      getById('ia-error').textContent = validationError;
      return;
    }

    try {
      await postNui('appearance_save_identity', readIdentityFields());
      const appearance = state.pendingAppearance;
      state.pendingAppearance = null;
      state.interceptSave = false;
      setIdentityOpen(false);
      setStep('appearance');
      await postNui('appearance_save', appearance || {});
    } catch (error) {
      getById('ia-error').textContent = 'Falha ao salvar. Verifique os dados e tente novamente.';
      console.error('[ia-modern] failed to confirm identity', error);
    }
  };

  const bindIdentityEvents = () => {
    identityEl.querySelector('[data-action="cancel"]').addEventListener('click', cancelIdentity);
    identityEl.querySelector('[data-action="confirm"]').addEventListener('click', confirmIdentity);
  };

  const bindHudEvents = () => {
    hudEl.addEventListener('click', async (event) => {
      const target = event.target.closest('button');
      if (!target) return;

      const cam = target.dataset.cam;
      const turn = target.dataset.turn;

      if (cam === 'head') {
        await postNui('appearance_set_camera', 'head');
      } else if (cam === 'body') {
        await postNui('appearance_set_camera', 'body');
      } else if (turn === 'left') {
        await postNui('rotate_left', {});
      } else if (turn === 'right') {
        await postNui('rotate_right', {});
      }
    });
  };

  const hydrateConfig = async () => {
    try {
      const config = await postNui('appearance_get_modern_ui_config', {});
      state.identityEnabled = config?.identityEnabled !== false;
      state.assets = config?.assets || {};
    } catch (error) {
      state.identityEnabled = true;
      state.assets = {};
    }
  };

  window.fetch = async (input, init) => {
    try {
      const url = typeof input === 'string' ? input : input?.url || '';
      const isAppearanceSave = typeof url === 'string' && /\/appearance_save$/.test(url);
      if (state.identityEnabled && state.nuiVisible && isAppearanceSave && !state.interceptSave) {
        state.interceptSave = true;
        state.pendingAppearance = JSON.parse(init?.body || '{}');
        setIdentityOpen(true);
        setStep('identity');
        return new Response(JSON.stringify(1), {
          status: 200,
          headers: { 'Content-Type': 'application/json' },
        });
      }
    } catch (error) {
      console.error('[ia-modern] fetch intercept failed', error);
    }

    return nativeFetch(input, init);
  };

  window.addEventListener('message', (event) => {
    const type = event?.data?.type;
    if (OPEN_EVENTS.has(type)) {
      state.nuiVisible = true;
      setRootState(true);
      setStep('appearance');
      if (!state.identityEnabled) {
        setIdentityOpen(false);
      }
    } else if (CLOSE_EVENTS.has(type)) {
      state.nuiVisible = false;
      state.interceptSave = false;
      state.pendingAppearance = null;
      setIdentityOpen(false);
      setRootState(false);
    }
  });

  window.addEventListener('error', (event) => {
    console.error('[ia-modern] runtime error', event.error || event.message);
  });

  const bootstrap = async () => {
    document.body.appendChild(hudEl);
    document.body.appendChild(identityEl);

    bindIdentityEvents();
    bindHudEvents();
    await hydrateConfig();
  };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', bootstrap, { once: true });
  } else {
    bootstrap().catch(console.error);
  }
})();
