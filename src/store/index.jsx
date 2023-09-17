import moment from "moment";
import { createGlobalState } from "react-hooks-global-state";

const { setGlobalState, useGlobalState, getGlobalState } = createGlobalState({
  createModal: "scale-0",
  updateModal: "scale-0",
  deleteModal: "scale-0",
  backModal: "scale-0",
  withdrawModal: "scale-0",
  connectedAccount: "",
  projects: [],
  unbackedProjects: [],
  project: null,
  stats: null,
  backers: [],
});

const truncate = (text, startChars, endChars, maxLength) => {
  if (text.length > maxLength) {
    let start = text.substring(0, startChars);
    let end = text.substring(text.length - endChars, text.length);
    while (start.length + end.length < maxLength) {
      start = start + ".";
    }
    return start + end;
  }
  return text;
};

const daysRemaining = (days) => {
  let todaysdate = moment().format("YYYY-MM-DD HH:mm");
  todaysdate = moment(todaysdate);
  days = Number((days + "000").slice(0));
  days = moment(days).format("YYYY-MM-DD HH:mm");
  days = moment(days);

  const differenceInMinutes = days.diff(todaysdate, "minutes");
  const differenceInHours = Math.floor(differenceInMinutes / 60);
  const differenceInDays = Math.floor(differenceInHours / 24);

  if (differenceInDays === 0) {
    if (differenceInHours === 0) {
      return differenceInMinutes === 1
        ? `${differenceInMinutes} minute`
        : `${differenceInMinutes} minutes`;
    } else {
      return differenceInHours === 1
        ? `${differenceInHours} hour`
        : `${differenceInHours} hours`;
    }
  } else {
    return differenceInDays === 1
      ? `${differenceInDays} day`
      : `${differenceInDays} days`;
  }
};

export {
  useGlobalState,
  setGlobalState,
  getGlobalState,
  truncate,
  daysRemaining,
};
