x = 20;
y = 20;

outputBox = new Textbox(fntConsolas, room_width - 40, (room_height - 60)/2);

outputBox.SetContent(@"
’Twas brillig, and the slithy toves
      Did gyre and gimble in the wabe:
All mimsy were the borogoves,
      And the mome raths outgrabe.

“Beware the Jabberwock, my son!
      The jaws that bite, the claws that catch!
Beware the Jubjub bird, and shun
      The frumious Bandersnatch!”

He took his vorpal sword in hand;
      Long time the manxome foe he sought—
So rested he by the Tumtum tree
      And stood awhile in thought. 
");

outputBox.SetCanType(false);