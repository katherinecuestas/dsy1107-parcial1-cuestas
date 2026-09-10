exports.handler = async (event) => {
  const grupos = event.request.groupConfiguration.groupsToOverride || [];

  const scopesPorGrupo = {
    solicitantes: ["solicitud:crear", "solicitud:leer"],
    aprobadores: ["solicitud:leer", "solicitud:aprobar", "solicitud:rechazar"],
  };

  let scopes = [];
  for (const grupo of grupos) {
    if (scopesPorGrupo[grupo]) {
      scopes = scopes.concat(scopesPorGrupo[grupo]);
    }
  }

  event.response = {
    claimsAndScopeOverrideDetails: {
      accessTokenGeneration: {
        scopesToAdd: scopes,
      },
    },
  };

  return event;
};