import { Application } from "@hotwired/stimulus";

const application = Application.start();
const env = document.body.getAttribute("data-rails-env");

application.debug = env === "development" ? true : false;
window.Stimulus = application;

export { application };
