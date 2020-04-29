import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["input", "counter"]

  connect() {
    this.maxCount = +this.data.get("max-count");
    this.count();
  }

  count() {
    this.currentCount = this.inputTarget.value.length;
    this._setCounter();
  }

  _setCounter() {
    this.counterTarget.innerHTML = `${ this.currentCount }/${ this.maxCount }`;
    if (this.currentCount > this.maxCount) {
      this.counterTarget.classList.add("text-red-600");
      this.counterTarget.classList.add("font-bold");
    } else {
      this.counterTarget.classList.remove("text-red-600");
      this.counterTarget.classList.remove("font-bold");
    }
  }
}