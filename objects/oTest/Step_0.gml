outputBox.Step(x, y, mouse_x, mouse_y, mouse_check_button(mb_left));
inputBox.Step(x, y2, mouse_x, mouse_y, mouse_check_button(mb_left));

if (inputBox.GetReturnPressed())
{
    outputBox.AppendContent("\n" + inputBox.GetContent());
    inputBox.SetContent("");
}