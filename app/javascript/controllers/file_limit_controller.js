import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["fileinput"]
    static values = { maxFiles: Number }

    connect() {
        this.fileinputTarget.addEventListener("change", this.checkFileLimit.bind(this));
    }

    disconnect() {
        this.fileinputTarget.removeEventListener("change", this.checkFileLimit.bind(this));
    }

    checkFileLimit(event) {
        const files = event.target.files
        if (files.length > this.maxFilesValue) {
            alert(`Вы можете загрузить не более ${this.maxFilesValue} файлов.`);
            event.target.value = "";
        }
    }
}
