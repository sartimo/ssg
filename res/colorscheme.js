let darkMode = localStorage.getItem("dark-mode");
const darkModeToggleSwitch = document.querySelector("#colorscheme-toggle")

function enableDarkMode() {
  document.body.classList.add("dark-mode");
  document.querySelector("#colorscheme-toggle-switch").classList.add("fa-flip-horizontal");
  localStorage.setItem("dark-mode", "enabled");
}

function disableDarkMode() {
  document.body.classList.remove("dark-mode");
  document.querySelector("#colorscheme-toggle-switch").classList.remove("fa-flip-horizontal");
  localStorage.setItem("dark-mode", null);
}

if (darkMode === "enabled") {
  enableDarkMode();
} else {
  disableDarkMode();
}

darkModeToggleSwitch.addEventListener("click", () => {
  darkMode = localStorage.getItem("dark-mode");
  if (darkMode === "enabled") {
    disableDarkMode();
  } else {
    enableDarkMode();
  }
});
