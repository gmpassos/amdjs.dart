define(['amdCalc'], function (calc) {
    return {
        square: function (a) {
            return calc.mul(a, a);
        }
    };
});
