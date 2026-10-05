export function isEligibleByAge(gender: "female" | "male" | "other", dobIsoDate: string): boolean {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(dobIsoDate);
  if (!match) return false;
  const birthDateUtc = Date.UTC(Number(match[1]), Number(match[2]) - 1, Number(match[3]));
  if (new Date(birthDateUtc).toISOString().slice(0, 10) !== dobIsoDate) return false;

  const minimumAge = gender === "male" ? 21 : 18;
  const localToday = new Map(
    new Intl.DateTimeFormat("en-CA", {
      timeZone: "Asia/Kolkata",
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
    }).formatToParts(new Date()).map((part) => [part.type, part.value]),
  );
  const year = Number(localToday.get("year"));
  const month = Number(localToday.get("month")) - 1;
  const day = Number(localToday.get("day"));
  const cutoff = new Date(Date.UTC(
    year - minimumAge,
    month,
    day,
  ));
  return birthDateUtc <= cutoff.getTime();
}
