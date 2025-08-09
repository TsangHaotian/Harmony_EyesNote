import NoteDetailTest from './NoteDetail.test'
import SettingsTest from './Settings.test'
import abilityTest from './Ability.test';

export default function testsuite() {
  abilityTest();
  SettingsTest()
  NoteDetailTest()
}