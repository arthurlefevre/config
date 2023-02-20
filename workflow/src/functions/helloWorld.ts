import randomNumber from "./randomNumber";
/**
 *
 * @returns Promise<string>
 */
export default function helloWorld(): string {
  console.log("Helloworld");
  return `Hello world : ${randomNumber()}`;
}
