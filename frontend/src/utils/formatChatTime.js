export function formatChatTime(isoString) {
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
        return `Ahora`;  
      }
      return `Hace ${diffMinutes} min`;
    }
    return `Hace ${diffHours} hs`;
  }

  // Ayer
  if (diffDays === 1) {
    return 'Ayer';
  }

  // Entre 2 y 6 días → día de la semana
  if (diffDays < 7) {
    return date.toLocaleDateString('es-AR', {
      weekday: 'long'
    }).replace(/^./, c => c.toUpperCase());
  }

  // 7 días o más → fecha completa
  return date.toLocaleDateString('es-AR');
}

export function formatDayLabel(isoString) {
  const date = new Date(isoString)
  const now = new Date()

  const startOfDate = new Date(date.getFullYear(), date.getMonth(), date.getDate())
  const startOfNow = new Date(now.getFullYear(), now.getMonth(), now.getDate())

  const diffDays = Math.floor(
    (startOfNow - startOfDate) / 86400000
  )

  if (diffDays === 0) return 'Hoy'
  if (diffDays === 1) return 'Ayer'
  if (diffDays < 7) {
    return date.toLocaleDateString('es-AR', { weekday: 'long' })
      .replace(/^./, c => c.toUpperCase())
  }

  return date.toLocaleDateString('es-AR')
}

export function getCurrentISOTimeString() {
  return new Date().toISOString();
}
