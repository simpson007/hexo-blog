---
title: 17 个常用的 JavaScript 简写技巧
date: 2022-09-01
updated: 2022-09-01
categories: 学海拾贝集
keywords: 学海拾贝集
top_img: /img/tutorials/tutorials-bg.png
cover: /img/tutorials/tutorials-cover.png
---

在日常开发中，我们经常会写出一些冗长的 JavaScript 代码。虽然功能能实现，但未必简洁。  
其实，JavaScript 提供了很多语法糖和小技巧，可以让我们用更短的代码完成同样的事情。  
掌握这些简写方式，不仅能提升代码可读性，还能在一定程度上提高开发效率。  

---

### 1. 三元运算符  
**传统写法：**
```js
let result;
if (someCondition) {
  result = 'yes';
} else {
  result = 'no';
}
```

**简写方式：**

```js
const result = someCondition ? 'yes' : 'no';
```

✅ **版本要求：ES3 (1999)**

---

### 2. 空值合并运算符

**传统写法：**

```js
let name = userName !== undefined && userName !== null ? userName : 'Guest';
```

**简写方式：**

```js
let name = userName ?? 'Guest';
```

✅ **版本要求：ES11 (2020)**

---

### 3. 可选链操作符

**传统写法：**

```js
const street = user && user.address && user.address.street;
```

**简写方式：**

```js
const street = user?.address?.street;
```

✅ **版本要求：ES11 (2020)**

---

### 4. 数组去重

**传统写法：**

```js
const arr = [1, 2, 2, 3];
const unique = arr.filter((item, index) => arr.indexOf(item) === index);
```

**简写方式：**

```js
const unique = [...new Set([1, 2, 2, 3])];
```

✅ **版本要求：ES6 (2015)**

---

### 5. 快速取整

**传统写法：**

```js
const floor = Math.floor(4.9); // 4
```

**简写方式：**

```js
const floor = ~~4.9; // 4
```

✅ **版本要求：ES3 (1999)**

**⚠️ 注意事项**

* `~~num` 是 **向零截断**，去掉小数部分：

```js
~~4.9   // 4
~~-4.9  // -4
```

* `Math.floor(num)` 是 **向下取整**，小于等于原数：

```js
Math.floor(4.9)  // 4
Math.floor(-4.9) // -5
```

* **结论**：正数可以互换，但负数场景要小心，`~~` 并不等于向下取整。

---

### 6. 合并对象

**传统写法：**

```js
const merged = Object.assign({}, obj1, obj2);
```

**简写方式：**

```js
const merged = { ...obj1, ...obj2 };
```

✅ **版本要求：ES9 (2018)**

---

### 7. 短路求值

**传统写法：**

```js
if (condition) {
  doSomething();
}
```

**简写方式：**

```js
condition && doSomething();
```

✅ **版本要求：ES3 (1999)**

---

### 8. 默认参数值

**传统写法：**

```js
function greet(name) {
  name = name || 'Guest';
  console.log(`Hello ${name}`);
}
```

**简写方式：**

```js
const greet = (name = 'Guest') => console.log(`Hello ${name}`);
```

✅ **版本要求：ES6 (2015)**

---

### 9. 解构赋值

**传统写法：**

```js
const first = arr[0];
const second = arr[1];
```

**简写方式：**

```js
const [first, second] = arr;
```

✅ **版本要求：ES6 (2015)**

---

### 10. 字符串转数字

**传统写法：**

```js
const num = parseInt('123', 10);
```

**简写方式：**

```js
const num = +'123';
```

✅ **版本要求：ES3 (1999)**

---

### 11. 多重条件判断

**传统写法：**

```js
if (value === 1 || value === 2 || value === 3) {
  // ...
}
```

**简写方式：**

```js
if ([1, 2, 3].includes(value)) {
  // ...
}
```

✅ **版本要求：ES6 (2015)**

---

### 12. 幂运算

**传统写法：**

```js
Math.pow(2, 3); // 8
```

**简写方式：**

```js
2 ** 3; // 8
```

✅ **版本要求：ES7 (2016)**

---

### 13. 对象属性简写

**传统写法：**

```js
const obj = { x: x, y: y };
```

**简写方式：**

```js
const obj = { x, y };
```

✅ **版本要求：ES6 (2015)**

---

### 14. 数组映射

**传统写法：**

```js
const doubled = numbers.map(function(num) {
  return num * 2;
});
```

**简写方式：**

```js
const doubled = numbers.map(num => num * 2);
```

✅ **版本要求：ES6 (2015)**

---

### 15. 交换变量值

**传统写法：**

```js
let temp = a;
a = b;
b = temp;
```

**简写方式：**

```js
[a, b] = [b, a];
```

✅ **版本要求：ES6 (2015)**

---

### 16. 动态对象属性

**传统写法：**

```js
const obj = {};
obj[dynamic + 'Name'] = value;
```

**简写方式：**

```js
const obj = {
  [`${dynamic}Name`]: value
};
```

✅ **版本要求：ES6 (2015)**

---

### 17. 数组填充 `fill`

**传统写法：**

```js
let arr = [];
for (let i = 0; i < 3; i++) {
  arr[i] = 0;
}
```

**简写方式：**

```js
const arr = new Array(3).fill(0);
```

✅ **版本要求：ES6 (2015)**

**⚠️ 注意事项**

* `fill` 对 **对象类型** 会共享同一个引用：

```js
const arr = new Array(3).fill({ x: 0 });
arr[0].x = 1;
console.log(arr);
// 输出：[{x:1},{x:1},{x:1}]
```

* 如果希望每个元素独立，需要用 `map` 或循环：

```js
const arr = Array.from({ length: 3 }, () => ({ x: 0 }));
arr[0].x = 1;
console.log(arr);
// 输出：[{x:1},{x:0},{x:0}]
```