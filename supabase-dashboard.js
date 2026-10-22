/* JDS Keyhold: authenticated landlord dashboard integration.
   Uses only the public Supabase anon/publishable key; RLS remains mandatory. */
(() => {
  const cfg = window.JDS_SUPABASE_URL && window.JDS_SUPABASE_ANON_KEY;
  const configured = cfg && /^https:\/\/[a-z0-9-]+\.supabase\.co$/i.test(window.JDS_SUPABASE_URL) && !/YOUR_PROJECT|YOUR_SUPABASE|placeholder/i.test(window.JDS_SUPABASE_ANON_KEY);
  const $ = s => document.querySelector(s);
  const fmt = n => 'UGX ' + Number(n || 0).toLocaleString('en-US');
  const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  const banner = (message, error=false) => {
    let el = $('#backendNotice');
    if (!el) { el=document.createElement('div'); el.id='backendNotice'; el.style.cssText='margin:12px 0;padding:12px 16px;border-radius:10px;font-size:13px;line-height:1.5;border:1px solid #d6deea;background:#f5f8fc;color:#24364b'; const wrap=$('.content-wrap'); if(wrap) wrap.prepend(el); }
    el.style.borderColor = error ? '#e6b6b6' : '#d6deea'; el.style.background = error ? '#fff5f5' : '#f5f8fc'; el.textContent=message;
  };
  if (!configured) {
    banner('Preview mode: add your Supabase project URL and public publishable/anon key to supabase-config.js to enable your live landlord dashboard. Your private service-role key is not needed here.');
    return;
  }
  if (!window.supabase?.createClient) { banner('Supabase client library did not load. Check your internet connection and reload.', true); return; }
  document.querySelector('.demo-banner')?.classList.add('hidden');
  const client = window.supabase.createClient(window.JDS_SUPABASE_URL, window.JDS_SUPABASE_ANON_KEY, {auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true}});
  let orgId=null, properties=[], units=[], payments=[];
  const stopPreviewSubmit = async e => {
    if (e.target?.id !== 'modalForm') return;
    e.preventDefault(); e.stopImmediatePropagation();
    const form=e.target, d=Object.fromEntries(new FormData(form).entries());
    if (!orgId) { banner('Your account has no landlord workspace yet. Run the safe one-time setup SQL in supabase/SAFE-EXISTING-ACCOUNT-SETUP.sql, then reload this page.', true); return; }
    const submit=$('#submitModal'); if(submit){submit.disabled=true;submit.textContent='Saving…';}
    try {
      const modalTitle=($('#modalTitle')?.textContent||'').toLowerCase(); if (!modalTitle.includes('property')) { throw new Error('This integration currently connects the landlord property and unit workflow. Tenant, billing, meter and document workflows still need their own database integration; no preview transaction was saved.'); }
      const total=Number(d.units), occupied=Number(d.occupied||0);
      if (!d.name?.trim() || !d.location?.trim() || !Number.isInteger(total) || total<1 || total>5000 || occupied<0 || occupied>total) throw new Error('Check the property name, location, unit count, and occupied unit count.');
      const bits=d.location.split(',').map(x=>x.trim());
      const {data:p,error:pe}=await client.from('properties').insert({organization_id:orgId,name:d.name.trim(),address_line:d.location.trim(),area:bits[0]||null,city:bits.length>1?bits.slice(1).join(', '):null,property_type:(d.type||'Residential').toLowerCase().replaceAll(' ','_')}).select('*').single();
      if(pe) throw pe;
      const rows=Array.from({length:total},(_,i)=>({organization_id:orgId,property_id:p.id,unit_code:`${String(i+1).padStart(2,'0')}`,display_name:`Unit ${String(i+1).padStart(2,'0')}`,market_rent_ugx:Math.max(0,Number(d.rent||0)),active:true}));
      const {error:ue}=await client.from('units').insert(rows);
      if(ue){await client.from('properties').delete().eq('id',p.id).eq('organization_id',orgId);throw new Error('Property could not be completed because unit creation failed: '+ue.message);}
      if(window.closeModal) window.closeModal(); else $('#cancelModal')?.click();
      banner(`Saved “${p.name}” and created ${total} units in Supabase. The occupied count is not yet linked to tenant leases, so occupancy will show as vacant until tenancies are recorded.`);
      await loadDashboard();
      document.querySelector('[data-page="properties"]')?.click();
    } catch(err) { banner(err.message || 'Could not save property. Check Supabase permissions and try again.', true); }
    finally {if(submit){submit.disabled=false;submit.textContent='Save property';}}
  };
  // Capture phase ensures the legacy preview handler cannot save a second, fake record.
  document.addEventListener('submit', stopPreviewSubmit, true);
  // app.js keeps its modal mode in a closure; infer the current form from its title.
  const modalObserver = new MutationObserver(()=>{const title=$('#modalTitle')?.textContent||'';window.JDS_MODAL_MODE=title.toLowerCase().includes('property')?'property':title.toLowerCase().includes('payment')?'payment':title.toLowerCase().includes('tenant')?'tenant':title.toLowerCase().includes('reading')?'reading':'other';});
  if($('#modalTitle')) modalObserver.observe($('#modalTitle'),{childList:true,subtree:true,characterData:true});
  function renderProperties(){
    const grid=$('#propertyGrid'); if(grid) grid.innerHTML=properties.length?properties.map((p,i)=>{const us=units.filter(u=>u.property_id===p.id), occupied=0;return `<article class="property-card"><div class="property-art ${['art-one','art-two','art-three'][i%3]}"><span class="property-tag">${esc((p.property_type||'residential').replaceAll('_',' ').toUpperCase())}</span><div class="building-lines"></div></div><div class="property-info"><div><h3>${esc(p.name)}</h3><p>${esc(p.address_line||p.area||p.city||'')}</p></div><span class="occupancy-chip">${us.length} units</span></div><div class="property-metrics"><div><small>Total units</small><b>${us.length}</b></div><div><small>Monthly rent</small><b>${fmt(us.reduce((s,u)=>s+Number(u.market_rent_ugx||0),0))}</b></div><div><small>Occupied</small><b>${occupied} <em>/ ${us.length}</em></b></div></div><button class="property-open" data-db-property="${p.id}">Property saved <span>✓</span></button></article>`}).join(''):'<div class="generic-empty"><div class="empty-icon">⌂</div><h3>No properties yet</h3><p>Add your first property to start building your portfolio.</p><button class="btn btn-primary" id="firstPropertyBtn">＋ Add your first property</button></div>';
    $('#firstPropertyBtn')?.addEventListener('click',()=>$('#addPropertyBtn')?.click());
    const navCount=document.querySelector('[data-page="properties"] .nav-count'); if(navCount)navCount.textContent=String(properties.length);
    const totalUnits=units.length;
    if($('#occupiedValue'))$('#occupiedValue').innerHTML=`0 <small>/ ${totalUnits}</small>`;
    const occCaption=document.querySelector('#occupiedValue')?.parentElement?.querySelector('.stat-caption');if(occCaption)occCaption.textContent=`${totalUnits} units across ${properties.length} properties; occupancy updates when leases are connected.`;
    const propertySub=document.querySelector('.property-panel .panel-heading p');if(propertySub)propertySub.textContent=`${properties.length} properties in your workspace`;
    const collected=$('#collectedValue');if(collected)collected.textContent=fmt(payments.reduce((s,p)=>s+Number(p.amount_ugx||0),0));
    const pc=$('#paymentsCount');if(pc)pc.textContent=String(payments.length);
    const out=$('#outstandingValue');if(out)out.textContent='Not available yet';
  }
  async function loadDashboard(){
    const {data:{session},error:se}=await client.auth.getSession();
    if(se)throw se;
    if(!session){banner('You are not signed in. Sign in through JDS Keyhold, then return to the dashboard.');return;}
    const {data:members,error:me}=await client.from('organization_members').select('organization_id,role').eq('user_id',session.user.id).limit(1);
    if(me)throw me;
    if(!members?.length){banner('You are signed in, but this account has no landlord workspace membership yet. Run supabase/SAFE-EXISTING-ACCOUNT-SETUP.sql once in the Supabase SQL Editor, then reload.',true);return;}
    orgId=members[0].organization_id;
    const [{data:orgs,error:oe},{data:ps,error:pe},{data:us,error:ue},{data:pay,error:paye}]=await Promise.all([
      client.from('organizations').select('id,name').eq('id',orgId).limit(1),
      client.from('properties').select('*').eq('organization_id',orgId).is('archived_at',null).order('created_at',{ascending:false}),
      client.from('units').select('*').eq('organization_id',orgId).eq('active',true),
      client.from('payments').select('amount_ugx,status,received_at').eq('organization_id',orgId).limit(1000)
    ]);
    if(oe||pe||ue||paye)throw oe||pe||ue||paye;
    properties=ps||[];units=us||[];payments=(pay||[]).filter(p=>p.status==='confirmed');
    const ws=document.querySelector('.workspace b');if(ws)ws.textContent=orgs?.[0]?.name||'My Property Workspace';
    const bannerEl=$('#backendNotice');if(bannerEl)bannerEl.remove();
    renderProperties();
    const genericAction=$('#genericAction'); if(genericAction)genericAction.onclick=()=>{if((document.querySelector('#genericTitle')?.textContent||'').toLowerCase().includes('propert'))$('#addPropertyBtn')?.click();};
    const oldGeneric=$('#genericContent');
    const navProps=document.querySelector('[data-page="properties"]');
    if(navProps)navProps.addEventListener('click',()=>{setTimeout(()=>{if($('#genericTitle')?.textContent==='Properties'){if(oldGeneric)oldGeneric.innerHTML=`<div class="panel-heading"><div><h2>Your property portfolio</h2><p>${properties.length} properties · ${units.length} units</p></div><span class="status-pill success">Connected to Supabase</span></div>${properties.length?`<div class="generic-list">${properties.map(p=>`<div class="generic-list-item"><div class="list-symbol">⌂</div><div><b>${esc(p.name)}</b><small>${esc(p.address_line||p.area||'')} · ${units.filter(u=>u.property_id===p.id).length} units</small></div><span class="status-pill success">Saved</span></div>`).join('')}</div>`:'<div class="generic-empty"><h3>No properties yet</h3><p>Use “Add property” to create your first property and its units.</p></div>'}`}},0);},{once:true});
    const demoBanner=$('.demo-banner');if(demoBanner)demoBanner.classList.add('hidden');
    banner(`Connected to Supabase as ${session.user.email||'your account'}. Loaded ${properties.length} properties and ${units.length} units from your workspace. Property creation is connected; tenant, billing, utility and document workflows remain to be integrated.`);
  }
  client.auth.onAuthStateChange((_event,session)=>{if(session)loadDashboard().catch(e=>banner('Supabase error: '+e.message,true));});
  loadDashboard().catch(e=>banner('Could not load your Supabase dashboard: '+e.message+'. Check that your public key is correct and RLS policies are installed.',true));
  // Expose a harmless sign-out action for the app shell, without exposing credentials.
  window.JDS_SIGN_OUT=async()=>{await client.auth.signOut();location.href='auth.html';};
})();
