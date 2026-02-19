export function formatAddedTime(isoString) {
  if (!isoString) return '';

  const date = new Date(isoString);
  const now = new Date();

  const diffMs = now - date;
  const diffMinutes = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMs / 3600000);
  const diffDays = Math.floor(diffMs / 86400000);

  // Hoy
  if (diffDays === 0) {
    if (diffMinutes < 60) {
      if (diffMinutes < 1) {
        return 'ahora';
      }
      return `hace ${diffMinutes} min`;
    }
    return `hace ${diffHours} hs`;
  }

  // Ayer
  if (diffDays === 1) {
    return 'ayer';
  }

  // Entre 2 y 6 días → día de la semana
  if (diffDays < 7) {
    const day = date.toLocaleDateString('es-AR', {
      weekday: 'long'
    });
    return `el ${day}`
  }

  // 7 días o más → fecha completa
  return `el ${date.toLocaleDateString('es-AR')}`;
}
