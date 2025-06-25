import React, { Component } from 'react';
import {
	StyleSheet,
	Animated,
	requireNativeComponent,
	UIManager,
	Platform,
} from 'react-native';

// Get the native component with proper typing support
const RNTScratchView = requireNativeComponent('RNTScratchView');

const AnimatedScratchView =
	RNTScratchView && Animated.createAnimatedComponent(RNTScratchView);

// Ensure commands are available for new architecture compatibility
const COMMANDS = {
	reset: UIManager.getViewManagerConfig
		? UIManager.getViewManagerConfig('RNTScratchView')?.Commands?.reset
		: UIManager.RNTScratchView?.Commands?.reset,
};

class ScratchView extends Component {
	constructor(props) {
		super(props);

		this.state = {
			animatedValue: new Animated.Value(1),
			isScratchDone: false,
			visible: true,
		};

		this.scratchOpacity = {
			opacity: this.state.animatedValue.interpolate({
				inputRange: [0, 1],
				outputRange: [1, 0],
			}),
		};
	}

	componentWillUnmount() {
		// Clean up timeout to prevent memory leaks
		if (this.hideTimeout) {
			clearTimeout(this.hideTimeout);
		}
	}

	_onImageLoadFinished = (e) => {
		const { id, onImageLoadFinished } = this.props;
		try {
			const success = JSON.parse(e.nativeEvent.success);
			onImageLoadFinished && onImageLoadFinished({ id, success });
		} catch (error) {
			console.warn('ScratchView: Error parsing image load result', error);
			onImageLoadFinished && onImageLoadFinished({ id, success: false });
		}
	};

	_onTouchStateChanged = (e) => {
		const { id, onTouchStateChanged } = this.props;
		try {
			const touchState = JSON.parse(e.nativeEvent.touchState);
			const { isScratchDone } = this.state;

			onTouchStateChanged && onTouchStateChanged({ id, touchState });
			if (
				!touchState &&
				isScratchDone &&
				!this.hideTimeout &&
				this.props.fadeOut !== false
			) {
				const that = this;
				this.hideTimeout = setTimeout(() => {
					that.setState({ visible: false });
				}, 300);
			}
		} catch (error) {
			console.warn('ScratchView: Error parsing touch state', error);
		}
	};

	_onScratchProgressChanged = (e) => {
		const { id, onScratchProgressChanged } = this.props;
		try {
			const { progressValue } = e.nativeEvent;
			onScratchProgressChanged &&
				onScratchProgressChanged({ id, value: parseFloat(progressValue) });
		} catch (error) {
			console.warn('ScratchView: Error parsing scratch progress', error);
		}
	};

	_onScratchDone = (e) => {
		const { id, onScratchDone } = this.props;
		try {
			const isScratchDone = JSON.parse(e.nativeEvent.isScratchDone);
			if (isScratchDone) {
				this.setState(
					{
						isScratchDone,
					},
					() => {
						this.fadeOut(() => {
							onScratchDone && onScratchDone({ id, isScratchDone });
						});
					}
				);
			}
		} catch (error) {
			console.warn('ScratchView: Error parsing scratch done state', error);
		}
	};

	fadeOut(postAction) {
		if (this.props.fadeOut === false) {
			postAction && postAction();
		} else {
			this.state.animatedValue.setValue(1);
			Animated.timing(this.state.animatedValue, {
				toValue: 0,
				duration: 300,
				useNativeDriver: true,
			}).start(postAction);
		}
	}

	render() {
		if (AnimatedScratchView && this.state.visible) {
			return (
				<AnimatedScratchView
					{...this.props}
					style={[styles.container, { opacity: this.state.animatedValue }]}
					onImageLoadFinished={this._onImageLoadFinished}
					onTouchStateChanged={this._onTouchStateChanged}
					onScratchProgressChanged={this._onScratchProgressChanged}
					onScratchDone={this._onScratchDone}
				/>
			);
		}
		return null;
	}
}

const styles = StyleSheet.create({
	container: {
		position: 'absolute',
		width: '100%',
		height: '100%',
	},
});

export default ScratchView;
