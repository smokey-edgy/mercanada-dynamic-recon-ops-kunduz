comment "Exported from Arsenal by Smoke";

comment "Remove existing items";
removeAllWeapons this;
removeAllItems this;
removeAllAssignedItems this;
removeUniform this;
removeVest this;
removeBackpack this;
removeHeadgear this;
removeGoggles this;

comment "Add containers";
this forceAddUniform "TRYK_U_B_Woodland";
this addVest "TRYK_V_ArmorVest_coyo";
this addBackpack "TRYK_B_FieldPack_Wood";
this addHeadgear "TRYK_H_Helmet_WOOD";

comment "Add weapons";

comment "Add items";
this linkItem "ItemMap";
this linkItem "ItemCompass";
this linkItem "ItemWatch";

comment "Set identity";
this setFace "PersianHead_A3_01";
this setSpeaker "Male02GRE";
