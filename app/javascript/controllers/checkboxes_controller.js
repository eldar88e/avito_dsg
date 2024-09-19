import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "toggleButton"]

  toggleCheckboxes() {
    const checkboxes = this.checkboxTargets;
    const button = this.toggleButtonTarget;
    const isChecked = checkboxes[0].checked;

    checkboxes.forEach(checkbox => {
      checkbox.checked = !isChecked;
    });

    button.textContent = isChecked ? "Выбрать все" : "Отменить выбор";
  }
}
