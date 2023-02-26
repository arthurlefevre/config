import randomNumber from "./randomNumber";
/**
 *
 * @returns Promise<string>
 */
export default async function helloWorld(): Promise<string> {
  console.log("Helloworld");
  return `Hello world : ${await randomNumber()}`;
}
