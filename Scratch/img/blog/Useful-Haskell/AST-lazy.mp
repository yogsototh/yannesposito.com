% DPI 180
gu:=2u;
z0=origin;
z1=z0 shifted (0,-gu);
z2=z1 shifted (-gu,-gu);
z3=z1 shifted (gu, -gu);

drawState(z1,"\mathtt{(-)}");
drawoptions(withcolor red);
drawState(z0,"\mathtt{fact}");
drawoptions(withcolor yellow);
drawState(z2,"3");
drawState(z3,"1");

drawoptions(withcolor base01);
drawarrow edge(z0,z1);
drawarrow edge(z1,z2);
drawarrow edge(z1,z3);
