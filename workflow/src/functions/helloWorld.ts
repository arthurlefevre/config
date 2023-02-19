import randomNumber from "./randomNumber";
/**
 *
 * @returns Promise<string>
 */
export default function helloWorld(): string {
  return `Hello world : ${randomNumber()}`;
}
