- allocated p (items)
- cap
- len 

```
[] // cap = 0, length = 0, p = null
// push(1)
[1, _, _, _] // cap = 4, len = 1, p = 0xabcadbacbad
// push(2)
[1, 2, _, _] // cap = 4, len = 2, p = 0xabcadbacbad
// push(3)
[1, 2, 3, _] // cap = 4, len = 3, p = 0xabcadbacbad
// push(4)
[1, 2, 3, 4] // cap = 4, len = 4, p = 0xabcadbacbad
// push(5)
[1, 2, 3, 4, 5, _, _, _] // cap = 8, len = 4, p = 0xbbadbacad
// pop() => 5
[1, 2, 3, 4, _, _, _, _] // cap = 8, len = 3, p = 0xbbadbacad
```