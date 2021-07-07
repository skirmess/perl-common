requires 'CPAN::Meta::YAML';
requires 'CPAN::Perl::Releases';
requires 'Carp';
requires 'File::pushd';
requires 'Git::Wrapper';
requires 'HTTP::Tiny';
requires 'JSON::PP';
requires 'Moo';
requires 'Moo::Role';
requires 'Path::Tiny';
requires 'Text::Template';
requires 'constant';
requires 'lib';
requires 'namespace::autoclean', '0.09';
requires 'perl', '5.010';
requires 'strict';
requires 'version', '0.77';
requires 'warnings';

on test => sub {
    requires 'Test::More', '0.88';
    requires 'lib';
    requires 'perl', '5.006';
    requires 'strict';
    requires 'warnings';
};

on develop => sub {
    requires 'CPANPLUS';
    requires 'JSON::MaybeXS';
    requires 'Path::Tiny';
    requires 'Perl::Critic';
    requires 'Perl::Critic::MergeProfile';
    requires 'Perl::Critic::Policy::Bangs::ProhibitBitwiseOperators';
    requires 'Perl::Critic::Policy::Bangs::ProhibitDebuggingModules';
    requires 'Perl::Critic::Policy::Bangs::ProhibitFlagComments';
    requires 'Perl::Critic::Policy::Bangs::ProhibitRefProtoOrProto';
    requires 'Perl::Critic::Policy::Bangs::ProhibitUselessRegexModifiers';
    requires 'Perl::Critic::Policy::BuiltinFunctions::ProhibitBooleanGrep';
    requires 'Perl::Critic::Policy::BuiltinFunctions::ProhibitComplexMappings';
    requires 'Perl::Critic::Policy::BuiltinFunctions::ProhibitDeleteOnArrays';
    requires 'Perl::Critic::Policy::BuiltinFunctions::ProhibitLvalueSubstr';
    requires 'Perl::Critic::Policy::BuiltinFunctions::ProhibitReturnOr';
    requires 'Perl::Critic::Policy::BuiltinFunctions::ProhibitReverseSortBlock';
    requires 'Perl::Critic::Policy::BuiltinFunctions::ProhibitShiftRef';
    requires 'Perl::Critic::Policy::BuiltinFunctions::ProhibitSleepViaSelect';
    requires 'Perl::Critic::Policy::BuiltinFunctions::ProhibitStringyEval';
    requires 'Perl::Critic::Policy::BuiltinFunctions::ProhibitStringySplit';
    requires 'Perl::Critic::Policy::BuiltinFunctions::ProhibitUniversalCan';
    requires 'Perl::Critic::Policy::BuiltinFunctions::ProhibitUniversalIsa';
    requires 'Perl::Critic::Policy::BuiltinFunctions::ProhibitUselessTopic';
    requires 'Perl::Critic::Policy::BuiltinFunctions::ProhibitVoidGrep';
    requires 'Perl::Critic::Policy::BuiltinFunctions::ProhibitVoidMap';
    requires 'Perl::Critic::Policy::BuiltinFunctions::RequireBlockGrep';
    requires 'Perl::Critic::Policy::BuiltinFunctions::RequireBlockMap';
    requires 'Perl::Critic::Policy::BuiltinFunctions::RequireGlobFunction';
    requires 'Perl::Critic::Policy::BuiltinFunctions::RequireSimpleSortBlock';
    requires 'Perl::Critic::Policy::ClassHierarchies::ProhibitAutoloading';
    requires 'Perl::Critic::Policy::ClassHierarchies::ProhibitExplicitISA';
    requires 'Perl::Critic::Policy::ClassHierarchies::ProhibitOneArgBless';
    requires 'Perl::Critic::Policy::CodeLayout::ProhibitFatCommaNewline';
    requires 'Perl::Critic::Policy::CodeLayout::ProhibitHardTabs';
    requires 'Perl::Critic::Policy::CodeLayout::ProhibitParensWithBuiltins';
    requires 'Perl::Critic::Policy::CodeLayout::ProhibitQuotedWordLists';
    requires 'Perl::Critic::Policy::CodeLayout::ProhibitTrailingWhitespace';
    requires 'Perl::Critic::Policy::CodeLayout::RequireConsistentNewlines';
    requires 'Perl::Critic::Policy::CodeLayout::RequireFinalSemicolon';
    requires 'Perl::Critic::Policy::CodeLayout::RequireTrailingCommaAtNewline';
    requires 'Perl::Critic::Policy::CodeLayout::RequireTrailingCommas';
    requires 'Perl::Critic::Policy::Compatibility::ConstantLeadingUnderscore';
    requires 'Perl::Critic::Policy::Compatibility::ConstantPragmaHash';
    requires 'Perl::Critic::Policy::Compatibility::ProhibitUnixDevNull';
    requires 'Perl::Critic::Policy::ControlStructures::ProhibitCStyleForLoops';
    requires 'Perl::Critic::Policy::ControlStructures::ProhibitCascadingIfElse';
    requires 'Perl::Critic::Policy::ControlStructures::ProhibitDeepNests';
    requires 'Perl::Critic::Policy::ControlStructures::ProhibitLabelsWithSpecialBlockNames';
    requires 'Perl::Critic::Policy::ControlStructures::ProhibitMutatingListFunctions';
    requires 'Perl::Critic::Policy::ControlStructures::ProhibitNegativeExpressionsInUnlessAndUntilConditions';
    requires 'Perl::Critic::Policy::ControlStructures::ProhibitPostfixControls';
    requires 'Perl::Critic::Policy::ControlStructures::ProhibitUnlessBlocks';
    requires 'Perl::Critic::Policy::ControlStructures::ProhibitUnreachableCode';
    requires 'Perl::Critic::Policy::ControlStructures::ProhibitUntilBlocks';
    requires 'Perl::Critic::Policy::ControlStructures::ProhibitYadaOperator';
    requires 'Perl::Critic::Policy::Documentation::ProhibitAdjacentLinks';
    requires 'Perl::Critic::Policy::Documentation::ProhibitBadAproposMarkup';
    requires 'Perl::Critic::Policy::Documentation::ProhibitDuplicateHeadings';
    requires 'Perl::Critic::Policy::Documentation::ProhibitLinkToSelf';
    requires 'Perl::Critic::Policy::Documentation::ProhibitParagraphEndComma';
    requires 'Perl::Critic::Policy::Documentation::ProhibitParagraphTwoDots';
    requires 'Perl::Critic::Policy::Documentation::ProhibitUnbalancedParens';
    requires 'Perl::Critic::Policy::Documentation::ProhibitVerbatimMarkup';
    requires 'Perl::Critic::Policy::Documentation::RequireEndBeforeLastPod';
    requires 'Perl::Critic::Policy::Documentation::RequireFilenameMarkup';
    requires 'Perl::Critic::Policy::Documentation::RequireLinkedURLs';
    requires 'Perl::Critic::Policy::Documentation::RequirePackageMatchesPodName';
    requires 'Perl::Critic::Policy::Documentation::RequirePodAtEnd';
    requires 'Perl::Critic::Policy::ErrorHandling::RequireCarping';
    requires 'Perl::Critic::Policy::ErrorHandling::RequireCheckingReturnValueOfEval';
    requires 'Perl::Critic::Policy::Freenode::AmpersandSubCalls';
    requires 'Perl::Critic::Policy::Freenode::ArrayAssignAref';
    requires 'Perl::Critic::Policy::Freenode::BarewordFilehandles';
    requires 'Perl::Critic::Policy::Freenode::ConditionalDeclarations';
    requires 'Perl::Critic::Policy::Freenode::ConditionalImplicitReturn';
    requires 'Perl::Critic::Policy::Freenode::DeprecatedFeatures';
    requires 'Perl::Critic::Policy::Freenode::DiscouragedModules';
    requires 'Perl::Critic::Policy::Freenode::DollarAB';
    requires 'Perl::Critic::Policy::Freenode::Each';
    requires 'Perl::Critic::Policy::Freenode::IndirectObjectNotation';
    requires 'Perl::Critic::Policy::Freenode::LexicalForeachIterator';
    requires 'Perl::Critic::Policy::Freenode::LoopOnHash';
    requires 'Perl::Critic::Policy::Freenode::ModPerl';
    requires 'Perl::Critic::Policy::Freenode::MultidimensionalArrayEmulation';
    requires 'Perl::Critic::Policy::Freenode::OpenArgs';
    requires 'Perl::Critic::Policy::Freenode::OverloadOptions';
    requires 'Perl::Critic::Policy::Freenode::POSIXImports';
    requires 'Perl::Critic::Policy::Freenode::PackageMatchesFilename';
    requires 'Perl::Critic::Policy::Freenode::PreferredAlternatives';
    requires 'Perl::Critic::Policy::Freenode::Prototypes';
    requires 'Perl::Critic::Policy::Freenode::StrictWarnings';
    requires 'Perl::Critic::Policy::Freenode::Threads';
    requires 'Perl::Critic::Policy::Freenode::Wantarray';
    requires 'Perl::Critic::Policy::Freenode::WarningsSwitch';
    requires 'Perl::Critic::Policy::Freenode::WhileDiamondDefaultAssignment';
    requires 'Perl::Critic::Policy::HTTPCookies';
    requires 'Perl::Critic::Policy::InputOutput::ProhibitBacktickOperators';
    requires 'Perl::Critic::Policy::InputOutput::ProhibitBarewordFileHandles';
    requires 'Perl::Critic::Policy::InputOutput::ProhibitExplicitStdin';
    requires 'Perl::Critic::Policy::InputOutput::ProhibitInteractiveTest';
    requires 'Perl::Critic::Policy::InputOutput::ProhibitJoinedReadline';
    requires 'Perl::Critic::Policy::InputOutput::ProhibitOneArgSelect';
    requires 'Perl::Critic::Policy::InputOutput::ProhibitReadlineInForLoop';
    requires 'Perl::Critic::Policy::InputOutput::ProhibitTwoArgOpen';
    requires 'Perl::Critic::Policy::InputOutput::RequireBracedFileHandleWithPrint';
    requires 'Perl::Critic::Policy::InputOutput::RequireCheckedClose';
    requires 'Perl::Critic::Policy::InputOutput::RequireCheckedOpen';
    requires 'Perl::Critic::Policy::InputOutput::RequireCheckedSyscalls';
    requires 'Perl::Critic::Policy::InputOutput::RequireEncodingWithUTF8Layer';
    requires 'Perl::Critic::Policy::Lax::ProhibitComplexMappings::LinesNotStatements';
    requires 'Perl::Critic::Policy::Miscellanea::ProhibitFormats';
    requires 'Perl::Critic::Policy::Miscellanea::ProhibitTies';
    requires 'Perl::Critic::Policy::Miscellanea::ProhibitUnrestrictedNoCritic';
    requires 'Perl::Critic::Policy::Miscellanea::ProhibitUselessNoCritic';
    requires 'Perl::Critic::Policy::Modules::PerlMinimumVersion';
    requires 'Perl::Critic::Policy::Modules::ProhibitAutomaticExportation';
    requires 'Perl::Critic::Policy::Modules::ProhibitConditionalUseStatements';
    requires 'Perl::Critic::Policy::Modules::ProhibitEvilModules';
    requires 'Perl::Critic::Policy::Modules::ProhibitModuleShebang';
    requires 'Perl::Critic::Policy::Modules::ProhibitMultiplePackages';
    requires 'Perl::Critic::Policy::Modules::ProhibitPOSIXimport';
    requires 'Perl::Critic::Policy::Modules::ProhibitUseQuotedVersion';
    requires 'Perl::Critic::Policy::Modules::RequireBarewordIncludes';
    requires 'Perl::Critic::Policy::Modules::RequireEndWithOne';
    requires 'Perl::Critic::Policy::Modules::RequireExplicitInclusion';
    requires 'Perl::Critic::Policy::Modules::RequireExplicitPackage';
    requires 'Perl::Critic::Policy::Modules::RequireFilenameMatchesPackage';
    requires 'Perl::Critic::Policy::Modules::RequireNoMatchVarsWithUseEnglish';
    requires 'Perl::Critic::Policy::Modules::RequirePerlVersion';
    requires 'Perl::Critic::Policy::Moo::ProhibitMakeImmutable';
    requires 'Perl::Critic::Policy::Moose::ProhibitDESTROYMethod';
    requires 'Perl::Critic::Policy::Moose::ProhibitLazyBuild';
    requires 'Perl::Critic::Policy::Moose::ProhibitMultipleWiths';
    requires 'Perl::Critic::Policy::Moose::ProhibitNewMethod';
    requires 'Perl::Critic::Policy::Moose::RequireCleanNamespace';
    requires 'Perl::Critic::Policy::Moose::RequireMakeImmutable';
    requires 'Perl::Critic::Policy::NamingConventions::Capitalization';
    requires 'Perl::Critic::Policy::NamingConventions::ProhibitAmbiguousNames';
    requires 'Perl::Critic::Policy::Objects::ProhibitIndirectSyntax';
    requires 'Perl::Critic::Policy::Perlsecret';
    requires 'Perl::Critic::Policy::References::ProhibitDoubleSigils';
    requires 'Perl::Critic::Policy::RegularExpressions::ProhibitCaptureWithoutTest';
    requires 'Perl::Critic::Policy::RegularExpressions::ProhibitEscapedMetacharacters';
    requires 'Perl::Critic::Policy::RegularExpressions::ProhibitFixedStringMatches';
    requires 'Perl::Critic::Policy::RegularExpressions::ProhibitSingleCharAlternation';
    requires 'Perl::Critic::Policy::RegularExpressions::ProhibitUnusedCapture';
    requires 'Perl::Critic::Policy::RegularExpressions::ProhibitUnusualDelimiters';
    requires 'Perl::Critic::Policy::RegularExpressions::ProhibitUselessTopic';
    requires 'Perl::Critic::Policy::RegularExpressions::RequireBracesForMultiline';
    requires 'Perl::Critic::Policy::RegularExpressions::RequireDotMatchAnything';
    requires 'Perl::Critic::Policy::RegularExpressions::RequireExtendedFormatting';
    requires 'Perl::Critic::Policy::RegularExpressions::RequireLineBoundaryMatching';
    requires 'Perl::Critic::Policy::Subroutines::ProhibitAmpersandSigils';
    requires 'Perl::Critic::Policy::Subroutines::ProhibitBuiltinHomonyms';
    requires 'Perl::Critic::Policy::Subroutines::ProhibitExplicitReturnUndef';
    requires 'Perl::Critic::Policy::Subroutines::ProhibitExportingUndeclaredSubs';
    requires 'Perl::Critic::Policy::Subroutines::ProhibitManyArgs';
    requires 'Perl::Critic::Policy::Subroutines::ProhibitNestedSubs';
    requires 'Perl::Critic::Policy::Subroutines::ProhibitQualifiedSubDeclarations';
    requires 'Perl::Critic::Policy::Subroutines::ProhibitReturnSort';
    requires 'Perl::Critic::Policy::Subroutines::ProhibitSubroutinePrototypes';
    requires 'Perl::Critic::Policy::Subroutines::ProhibitUnusedPrivateSubroutines';
    requires 'Perl::Critic::Policy::Subroutines::ProtectPrivateSubs';
    requires 'Perl::Critic::Policy::Subroutines::RequireFinalReturn';
    requires 'Perl::Critic::Policy::TestingAndDebugging::ProhibitNoStrict';
    requires 'Perl::Critic::Policy::TestingAndDebugging::ProhibitNoWarnings';
    requires 'Perl::Critic::Policy::TestingAndDebugging::ProhibitProlongedStrictureOverride';
    requires 'Perl::Critic::Policy::TestingAndDebugging::RequireTestLabels';
    requires 'Perl::Critic::Policy::TestingAndDebugging::RequireUseStrict';
    requires 'Perl::Critic::Policy::TestingAndDebugging::RequireUseWarnings';
    requires 'Perl::Critic::Policy::Tics::ProhibitManyArrows';
    requires 'Perl::Critic::Policy::Tics::ProhibitUseBase';
    requires 'Perl::Critic::Policy::TryTiny::RequireBlockTermination';
    requires 'Perl::Critic::Policy::TryTiny::RequireUse';
    requires 'Perl::Critic::Policy::ValuesAndExpressions::ConstantBeforeLt';
    requires 'Perl::Critic::Policy::ValuesAndExpressions::NotWithCompare';
    requires 'Perl::Critic::Policy::ValuesAndExpressions::PreventSQLInjection';
    requires 'Perl::Critic::Policy::ValuesAndExpressions::ProhibitArrayAssignAref';
    requires 'Perl::Critic::Policy::ValuesAndExpressions::ProhibitBarewordDoubleColon';
    requires 'Perl::Critic::Policy::ValuesAndExpressions::ProhibitCommaSeparatedStatements';
    requires 'Perl::Critic::Policy::ValuesAndExpressions::ProhibitComplexVersion';
    requires 'Perl::Critic::Policy::ValuesAndExpressions::ProhibitDuplicateHashKeys';
    requires 'Perl::Critic::Policy::ValuesAndExpressions::ProhibitEmptyCommas';
    requires 'Perl::Critic::Policy::ValuesAndExpressions::ProhibitEmptyQuotes';
    requires 'Perl::Critic::Policy::ValuesAndExpressions::ProhibitEscapedCharacters';
    requires 'Perl::Critic::Policy::ValuesAndExpressions::ProhibitImplicitNewlines';
    requires 'Perl::Critic::Policy::ValuesAndExpressions::ProhibitInterpolationOfLiterals';
    requires 'Perl::Critic::Policy::ValuesAndExpressions::ProhibitLongChainsOfMethodCalls';
    requires 'Perl::Critic::Policy::ValuesAndExpressions::ProhibitMismatchedOperators';
    requires 'Perl::Critic::Policy::ValuesAndExpressions::ProhibitMixedBooleanOperators';
    requires 'Perl::Critic::Policy::ValuesAndExpressions::ProhibitNoisyQuotes';
    requires 'Perl::Critic::Policy::ValuesAndExpressions::ProhibitNullStatements';
    requires 'Perl::Critic::Policy::ValuesAndExpressions::ProhibitQuotesAsQuotelikeOperatorDelimiters';
    requires 'Perl::Critic::Policy::ValuesAndExpressions::ProhibitSingleArgArraySlice';
    requires 'Perl::Critic::Policy::ValuesAndExpressions::ProhibitSpecialLiteralHeredocTerminator';
    requires 'Perl::Critic::Policy::ValuesAndExpressions::ProhibitUnknownBackslash';
    requires 'Perl::Critic::Policy::ValuesAndExpressions::ProhibitVersionStrings';
    requires 'Perl::Critic::Policy::ValuesAndExpressions::RequireConstantVersion';
    requires 'Perl::Critic::Policy::ValuesAndExpressions::RequireInterpolationOfMetachars';
    requires 'Perl::Critic::Policy::ValuesAndExpressions::RequireNumberSeparators';
    requires 'Perl::Critic::Policy::ValuesAndExpressions::RequireNumericVersion';
    requires 'Perl::Critic::Policy::ValuesAndExpressions::RequireQuotedHeredocTerminator';
    requires 'Perl::Critic::Policy::ValuesAndExpressions::RequireUpperCaseHeredocTerminator';
    requires 'Perl::Critic::Policy::ValuesAndExpressions::UnexpandedSpecialLiteral';
    requires 'Perl::Critic::Policy::Variables::ProhibitAugmentedAssignmentInDeclaration';
    requires 'Perl::Critic::Policy::Variables::ProhibitConditionalDeclarations';
    requires 'Perl::Critic::Policy::Variables::ProhibitEvilVariables';
    requires 'Perl::Critic::Policy::Variables::ProhibitLocalVars';
    requires 'Perl::Critic::Policy::Variables::ProhibitLoopOnHash';
    requires 'Perl::Critic::Policy::Variables::ProhibitMatchVars';
    requires 'Perl::Critic::Policy::Variables::ProhibitPackageVars';
    requires 'Perl::Critic::Policy::Variables::ProhibitPerl4PackageNames';
    requires 'Perl::Critic::Policy::Variables::ProhibitReusedNames';
    requires 'Perl::Critic::Policy::Variables::ProhibitUnusedVariables';
    requires 'Perl::Critic::Policy::Variables::ProhibitUnusedVarsStricter';
    requires 'Perl::Critic::Policy::Variables::ProhibitUselessInitialization';
    requires 'Perl::Critic::Policy::Variables::ProtectPrivateVars';
    requires 'Perl::Critic::Policy::Variables::RequireInitializationForLocalVars';
    requires 'Perl::Critic::Policy::Variables::RequireLexicalLoopIterators';
    requires 'Perl::Critic::Policy::Variables::RequireLocalizedPunctuationVars';
    requires 'Perl::Critic::Policy::Variables::RequireNegativeIndices';
    requires 'Pod::Wordlist';
    requires 'Test2::V0';
    requires 'Test::EOL';
    requires 'Test::Mojibake';
    requires 'Test::More', '0.88';
    requires 'Test::NoTabs';
    requires 'Test::Perl::Critic::XTFiles';
    requires 'Test::PerlTidy::XTFiles';
    requires 'Test::Pod', '1.26';
    requires 'Test::Pod::LinkCheck';
    requires 'Test::Pod::Links', '0.003';
    requires 'Test::RequiredMinimumDependencyVersion', '0.003';
    requires 'Test::Spelling', '0.12';
    requires 'Test::Version', '0.04';
    requires 'Test::XTFiles';
    requires 'XT::Util';
    requires 'lib';
    requires 'perl', '5.006';
    requires 'strict';
    requires 'warnings';
};

